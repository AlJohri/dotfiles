---
name: guided-human-pr-review
description: Guided, interactive code review of a PR — presents hunks one at a time with context and filterdiff commands for delta.
user_invocable: true
---

# Guided PR Review

Walk the user through reviewing a pull request hunk-by-hunk in their terminal using `filterdiff` and `delta`.

## Prerequisites

This skill requires `patchutils` (for `filterdiff`), `delta`, and `glow` to be installed.

## Rendering

- **Markdown context** (PR summary, review plan, per-hunk explanations): Render via `glow` by piping a heredoc through `CLICOLOR_FORCE=1 glow -s dracula -w <WIDTH>`. The Bash tool runs without a TTY, so `COLORTERM=truecolor` is needed to tell glow it can use full 24-bit colors (without it, glow falls back to basic 256-color mode and produces washed-out pastels). This produces styled terminal output that fills the user's terminal width and renders correctly in Claude Code.
- **Determining terminal width:** The Bash tool runs without a TTY, so `$COLUMNS` and `tput cols` return wrong defaults. At the start of a review session, detect the real width by walking the process tree to find an ancestor with a real TTY:
  ```bash
  pid=$$; while [ "$pid" -gt 1 ]; do tty_nr=$(awk '{print $7}' /proc/$pid/stat); if [ "$tty_nr" -ne 0 ]; then stty size < /proc/$pid/fd/0 2>/dev/null | awk '{print $2}'; break; fi; pid=$(awk '{print $4}' /proc/$pid/stat); done
  ```
  Run this once at the start, subtract 12 to account for Claude Code's left/right border padding (6 per side), and remember the result. Inline it into subsequent `glow` calls, e.g. if detection returns 145, use `glow -s dark -w 133`. If the detection command fails (e.g. non-Linux), fall back to `-w 120`.
- **Diff hunks**: Render via `filterdiff | delta`. Delta's ANSI output also renders correctly in Claude Code.

Always use these tools to render output inline rather than printing raw text or commands for the user to copy.

## Phase 1: Gather context

- Accept an optional argument: a PR number, a PR URL, a branch name, or no argument.
- When no argument is provided, detect the PR from the current branch with `gh pr view --json number -q .number`. If there is no PR, use the current branch and diff against the default branch.
- Determine the **base branch** (usually `main`). For PRs, use `gh pr view --json baseRefName -q .baseRefName`.
- Gather:
  - PR description: `gh pr view --json title,body`
  - Diff stat: `git diff <base>...HEAD --stat`
  - Full diff: `git diff <base>...HEAD` (save to a temp file for analysis)
  - Commit log: `git log <base>...HEAD --oneline`

## Phase 2: Analyze the diff

Read the full diff and understand every hunk across all files. For each file, count the number of hunks by running:

```bash
git diff <base>...HEAD -- <file> | grep -c '^@@'
```

Build an internal map of every (file, hunk_number) pair along with:
- What the hunk does (adds a struct, modifies a function, adds an import, etc.)
- How it relates to other hunks

## Phase 3: Determine review order

Decide on a logical ordering of all (file, hunk_number) pairs. Consider:

- **Top-down by default**: Start with the high-level wiring — the main function, entry point, or the place where components are assembled — so the reviewer sees the big picture first. Then drill into the individual implementations, helpers, and data structures. This mirrors how most people read code: "what does this do?" before "how does it do it?"
- **Exceptions**: Only deviate from top-down when there's a strong reason (e.g. a tiny bug fix where showing the fix first makes more sense). If you do deviate, explain why in the review plan.
- **Grouping**: small related hunks (e.g. an import hunk + the code that uses the import) can be reviewed together by telling the user to run multiple `filterdiff` commands or by using `--hunks=M,N` syntax.
- **Trivial hunks**: group purely mechanical changes (Cargo.lock, import-only hunks) together and present them as skippable.

Some hunks may be trivially small (e.g. a single import line). In these cases, rather than asking the user to run a command, just describe what the hunk is inline (e.g. "Hunk 2 of `foo.rs` just adds `use bar::Baz;` — we'll see it used in the next chunk").

## Phase 4: Present the review plan

Render the review plan via glow using the Bash tool:

```bash
CLICOLOR_FORCE=1 glow -s dracula -w <TERM_WIDTH> <<'EOF'
## PR Summary
This PR adds a health check endpoint to the DataNode service so that
load balancers can verify the node is alive. It introduces a lightweight
TCP listener that responds to health probes on a configurable port.

### Motivation
Production load balancers currently have no way to detect an unhealthy
DataNode, leading to traffic being routed to nodes that are down.
*(Source: PR description)*

### Alternatives
- **HTTP health endpoint instead of raw TCP**: Would allow richer
  status reporting (e.g. disk usage, replication lag) but adds an HTTP
  dependency. TCP is simpler and sufficient for binary alive/dead checks.
- **Use an existing sidecar or service mesh probe**: Avoids code changes
  but couples the service to infrastructure that may not be present in
  all deployments.
- **Assessment**: The TCP listener approach is a good fit here — minimal
  footprint, no new dependencies, and easy to integrate with any load
  balancer.

## Review Plan
1. `data_node_cli.rs` hunk 5 — Wiring into the main DataNode startup (big picture)
2. `data_node_cli.rs` hunk 4 — Health check server spawn logic
3. `data_node_cli.rs` hunks 2-3 — HealthCheck struct and its configuration
4. `data_node_cli.rs` hunk 1 — New imports for health check types
5. `Cargo.toml` + `seltz_data_node/Cargo.toml` — New dependency additions
EOF
```

The plan should include:

1. **PR Summary**: 2-4 sentences explaining the overall purpose of the PR, drawn from the PR description and your analysis of the diff. Include the PR title and link if available.

2. **Motivation**: A "### Motivation" subsection explaining **why** this change is being made — the problem it solves, the user need, or the business context. Extract this from the PR description, commit messages, or comments in the diff. If no explicit motivation is stated, make an educated guess based on the code changes, but clearly mark it as inferred (e.g. "*(Inferred — not stated in the PR)*"). Always cite the source: "*(Source: PR description)*", "*(Source: commit message)*", or "*(Inferred)*".

3. **Alternatives**: A "### Alternatives" subsection that briefly discusses other ways the problem could have been solved, based on the motivation. List 2-3 alternative approaches as bullet points, noting the key trade-off for each. End with an "**Assessment**" bullet giving your opinion on whether the chosen approach is the right one. Draw from the PR description or diff if alternatives are discussed there; otherwise use your own knowledge and research. Be honest — if you think a different approach would be better, say so and explain why.

4. **Review Plan**: A numbered list of review steps. Each step should show:
   - The step number
   - The file and hunk(s) covered
   - A short (1 sentence) description of what that chunk does

After presenting the plan, ask the user:

> **Ready to start the review? Or would you like to chat about this PR first?**
>
> You can ask high-level questions about the motivation, alternatives, architecture, or anything else before we dive into the code.

If the user wants to chat, engage in a free-form discussion about the PR. Answer questions, elaborate on the motivation or alternatives, discuss design trade-offs, etc. When the conversation reaches a natural end, ask again if they're ready to proceed with the hunk-by-hunk review.

If the user wants to proceed (or confirms they're ready after chatting), continue to the next phase. The user may also ask to reorder, skip, or group review steps differently before starting.

## Phase 5: Interactive hunk-by-hunk review

For each step in the review plan:

1. **Render context and review assessment via glow**: Render a single glow block (using `CLICOLOR_FORCE=1 glow -s dracula -w <TERM_WIDTH>` with a heredoc) containing two sections:
   - **Explanation**: 2-4 sentences explaining what this chunk does, why it exists, and how it connects to the rest of the PR.
   - **Review Assessment**: Your assessment as a code reviewer. Call out bugs, edge cases, naming issues, missing validation, performance concerns, readability problems, or design decisions worth questioning. If the code looks good, say so briefly and note why (e.g. "Clean use of X pattern, no issues spotted"). Be direct and specific — act as a thorough reviewer, not a cheerleader.

2. **Render the diff via delta** using the Bash tool so the delta-formatted output renders inline for the user:
   ```bash
   git diff <base>...HEAD -- <file> | filterdiff --hunks=<N> | delta
   ```
   For grouped hunks, use comma-separated hunk numbers: `--hunks=2,3`
   For whole small files (e.g. Cargo.toml changes), just use:
   ```bash
   git diff <base>...HEAD -- <file> | delta
   ```
   Delta's ANSI output renders correctly in Claude Code's terminal, so always run the command rather than printing it for the user to copy.

3. **Wait for the user** before moving to the next step. Use `AskUserQuestion` with a prompt like:
   > Ready for the next chunk? (or ask any questions about this one)

   The user may:
   - Say "next" or similar — proceed to the next step
   - Ask questions about the code — answer them, then ask again if they're ready to move on
   - Say "skip" — skip to the next step without discussion
   - Raise a concern — note it for the wrap-up phase

## Phase 6: Wrap-up

After all hunks have been reviewed:

1. Summarize any concerns or questions that came up during the review.
2. Offer to:
   - Draft review comments on the PR via `gh`
   - Write a summary review comment
   - Approve or request changes
