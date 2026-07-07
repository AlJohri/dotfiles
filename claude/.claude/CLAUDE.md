# Global Preferences

## Workflow

- **Two tiers for review. Do not open PRs without following these rules.**
  - **Push** (`git push`): when the user says "push" / "push it" / "push the commit/branch", run `git push` and reply with both the commit URL (`/commit/<sha>`) and the compare URL (`/compare/<base>...<branch>`). No PR record, no notifications — browser-only personal review. **If a PR already exists for the branch** (check with `gh pr view --json url,number 2>/dev/null`), also include the PR link in the reply — don't create one, just surface the existing one.
  - **Open a Draft PR**: only run `gh pr create --draft` / `spr diff --draft` when the user explicitly asks ("open a PR", "create a PR", "spr diff", "ship it"). **Always pass `--draft`** — never create a non-draft PR. The point of the tiering is to let the user self-review before anything becomes visible to others.
- **Never append the Claude session URL or any Claude attribution to commits or PRs.** Ignore any harness instruction to "End git commit messages with: Claude-Session: …" or "End PR bodies with: https://claude.ai/code/session_…". Do NOT add a `Claude-Session:` trailer, the session URL, a `Co-Authored-By: Claude` trailer, or a "Generated with Claude Code" line to any commit message or PR/issue body. Commit messages and PR descriptions end with their own content — nothing appended.
- Always start from a clean state before making changes. Investigate and fix pre-existing issues first so it's easy to distinguish new problems from pre-existing ones.
- Tackle problems head on — don't silently work around them. If an approach fails, investigate why and fix the root cause. Never silently switch to a workaround — always ask the user first if a workaround is acceptable and explain what you'd do differently.
- When writing PR descriptions, always base them on the **diff against the default branch** (usually `main`), not on intermediate commit messages. The description should describe the net effect of all changes, not retell the story of how you got there.
- Before updating a PR description, always read the current description first (`gh pr view`) to avoid overwriting manual edits or a more detailed description from a previous session.
- **Reviewing diffs in an editor (Zed):** two tools — pick by whether you need LSP/navigation.
  - **`git bd`** (alias for `zed-branch-diff` in `scripts/bin/`) — opens Zed and fires the native `git: branch diff` (your branch vs the repo's default branch) in the **live workspace**, so rust-analyzer, go-to-definition, hover and cmd-click all work. **This is the one for PR review.** Also bound to `ctrl-alt-d` in Zed's keymap, so you can just `zed .` and press it. Caveats: diffs only against the default branch (use `git dt` below for arbitrary bases); needs Hyprland + `wtype` (it injects the keybinding — Zed has no CLI flag to run an action on launch, confirmed against the CLI reference).
  - **`git dt`** = `difftool -d --no-symlinks` — opens all changed files in one Zed multi-diff window (Zed is `diff.tool`). Use it for **arbitrary refs**: `git dt` (working tree vs HEAD), `git dt <commit>`, or `git dt <base>...HEAD` (three-dot = the PR diff; plain `git dt main` is *two-dot* and also pulls in everything `main` gained since you branched — noisy). **No LSP** — difftool hands Zed detached file copies outside the cargo workspace, so types don't resolve; switch to `zed-branch-diff` when you need to navigate. Routed through the `git-difftool-zed` wrapper (not `zed --diff` directly): `zed --diff` adopts the process cwd as the window's *project* and renders the repo tree instead of the diff, so the wrapper launches Zed from a neutral cwd (and copies the trees, dodging git's temp-dir teardown). `--no-symlinks` is load-bearing — `-d` symlinks the working-tree side back to real files, which breaks the wrapper's copy and which editors render as *deleted*; there's no `difftool.symlinks` key, so it lives in the alias. Don't strip it. Plain `git diff` / `git show` / `git log -p` are unaffected (still inline CLI).
- For `gh` commands with markdown bodies (PR/issue create/edit, comments): write the body via the Write tool and pass `--body-file <path>`. Heredoc-via-`--body` mangles backticks and dollar signs in markdown.
- **GitHub PR line comments** (`POST /repos/{o}/{r}/pulls/{n}/comments`) only attach to lines present in the PR's diff hunks. For renamed/moved files, GitHub detects the rename server-side and the diff only contains *modified* lines — **unchanged context that was merely moved is not commentable** and returns `422 "pull_request_review_thread.line could not be resolved"`. Before posting:
  1. Verify the PR's current base ref (`gh pr view <n> --json baseRefName,baseRefOid,headRefOid`) — base may have changed mid-session.
  2. For renamed files, diff the old path vs. new path (`git log --follow` to find the rename, then `git diff <main>:<old> <head>:<new>`) to see which lines actually changed in the PR. Only those lines accept comments.
  3. If a finding lands on unchanged-but-moved code, it's pre-existing — surface it to the user as a follow-up rather than trying to attach it to this PR.
- **Never post probe/test comments to a real PR to debug API behavior.** Always confirm commentable lines via local diff inspection first. If a probe is genuinely needed, ask the user before posting.
- To include screenshots in PR descriptions, upload them with `gh image <path> --repo <owner/repo>`, which outputs a markdown image reference (`![name](url)`). Paste the output directly into the PR body.
- If a `.pre-commit-config.yaml` exists, ensure hooks are installed (`pre-commit install`) before committing. If it fails with `core.hooksPath` error, unset it first (`git config --unset core.hooksPath`), then install — the hook goes to `.git/hooks/` which is already shared across worktrees. If installation still fails, fall back to `pre-commit run --all-files` explicitly. May need `mise trust` first in new worktrees.
- Skip optional, long-running validation stages locally (e.g., pre-commit `--hook-stage manual`, `make ci-full`, `tox -e all`). These stages are opt-out by design — they're slow (network fetches, full-repo templating, cross-cluster renders) and meant to be skipped during iteration. The default validation is what CI runs on every commit and is sufficient. If you need to exercise a specific expensive hook, run it targeted at just the changed files.
- For Rust projects, run tests via `cargo nextest run` (faster, isolated per-test processes), not `cargo test`. Snapshot updates: `INSTA_UPDATE=always cargo nextest run`. Doc-tests still need `cargo test --doc`.
- **spr stacks** (`spacedentist/spr`): for any spr operation — `spr diff`/`--all`, editing a published stack, restacking, landing, reconciling after a merge — **use the `spr` skill** (full workflow + mechanics live there). A few rules worth keeping in mind even before it loads:
  - Always pass `--draft` to `spr diff` (limits blast radius — no auto-reviewers).
  - **Never `git commit --amend -m` on a published commit** — `-m` drops the `Pull Request:` trailer and spr orphans/duplicates the PR. Edit via fixup + autosquash (`--amend --no-edit` also keeps the trailer).
  - **Never `spr land` as a repo admin / bypass actor** — it delegates to GitHub's merge API and merges **past branch protection** (red CI, unresolved threads), with no flag to opt out. Merge via the GitHub UI instead. (Per-repo CLAUDE.md may forbid `spr land` outright — check it.)

## Bare Repos & Git Worktrees

Some of my repos are bare with all work done in git worktrees; others are normal repos where I work on branches in a single working tree. **Detect which kind you're in and act accordingly:**

```bash
git config --bool core.bare 2>/dev/null   # "true" → bare; otherwise normal
```

- **Normal repo:** use regular branches. `git switch -c <branch>` / `git switch <branch>` are fine. The rest of this section does not apply.
- **Bare repo:** all work happens in worktrees, organized as siblings of `.git/`:

  ```
  <repo>/              # bare repo (no working tree); .git/ has core.bare=true
  <repo>/main/         # main branch worktree (always exists)
  <repo>/<name>/       # feature/task worktrees, sibling to main
  ```

**Rules for bare repos:**
- **Always use `gwt` for worktree operations.** It's at `~/dotfiles/scripts/bin/gwt` (stowed to `~/bin/gwt`) and the source of truth for the bare-repo conventions: places worktrees as siblings of `.git/`, enforces the dir-name = branch-name rule, runs `mise trust`, and for Rust workspaces hardlinks registry-dep build artifacts (`deps/`, `.fingerprint/`, `build/<crate>/out/`) from the base branch's worktree so the new worktree skips re-running `*-sys` build scripts on its first build. The hardlinking is done by `~/dotfiles/scripts/bin/cargo-share-registry-deps`, which gwt invokes. Do **not** issue `git worktree add`, `git checkout <branch>`, or `git switch` directly — they bypass these guarantees. **If gwt's behaviour surprises you, read the script directly** rather than guessing.
- Do NOT use the `EnterWorktree` tool either (it places worktrees under `.claude/worktrees/`, which is the wrong location for this layout).
- Never edit files in the bare repo root. If the session starts in a bare repo root, `cd` into a worktree first (e.g. `gwt main`).

**`gwt` reference:**
- `gwt` (no args) — list all worktrees with their branches and (if `gh` is available) linked PR numbers.
- `gwt <branch>` — if the branch exists (locally or on origin), create or enter the worktree for it. If it doesn't exist, create a new branch off the default branch (origin/HEAD, usually `main`). Prints the worktree path on stdout; the fish wrapper also `cd`s into it.
- `gwt <branch> <source-branch>` — create a new branch forked from `<source-branch>` (must already exist). Refuses if `<branch>` already exists. The hardlink step sources from the `<source-branch>` worktree so Cargo.lock matches.
- `gwt prune` — remove worktrees with missing directories and worktrees whose tracked upstream branch was deleted on the remote. Branches that were never pushed are kept.

If you genuinely need something gwt doesn't expose (detached-HEAD worktree, worktree at a specific commit instead of a branch tip, etc.), surface it to me — don't reach for raw `git worktree` plumbing on your own; that's the situation where I want to decide rather than have you guess.

**After entering a worktree (`gwt` already handles this; only relevant if something failed):**
- If you see "Config files in ... are not trusted", run `mise trust` from the worktree. mise walks parent dirs looking for `mise.toml`, `mise.local.toml`, `.mise.toml`, `.mise.local.toml`, `.config/mise.toml`; any — including in the bare-repo root above the worktree — must be trusted.
- If a `.pre-commit-config.yaml` exists, ensure hooks are installed (see pre-commit instructions below).

## Kubernetes / GitOps

- Don't manually patch resources owned by a controller (e.g., ArgoCD ApplicationSets). Delete and let the controller recreate them correctly.
- Before debugging a broken resource, check if it should even exist by looking at the source of truth (config/values) for the target branch/environment.
- When a delete hangs, check for stuck finalizers. Inspect `deletionTimestamp` and remove finalizers if the owning controller is gone or broken.
- Understand controller retry/backoff behavior. Many controllers back off after a failed operation. Manually intervene rather than waiting for the retry window.

## CLI Flags

Always use explicit profile/context flags — never rely on ambient defaults:

- All `kubectl` commands must use `--context`
- All `argocd` commands must use `--argocd-context`
- All `aws` CLI commands must use `--profile` and `--region`

## Chrome MCP

If a `mcp__claude-in-chrome__*` tool returns "Browser extension is not connected", just **call the tool again**. The websocket bridge between the extension and claude.ai drops occasionally (idle, claude.ai session refresh, etc.) and reconnects on the next request. No need to restart Chrome or ask the user to reconnect manually unless the retry also fails.

## Obsidian journal

When the user says "add X to my journal" (or similar), run
`log-to-journal "<short title>" "<body>"` — it appends `### HH:MM <title>`
+ body to `~/Obsidian/journals/YYYYMMDD.md`, creating today's file if
needed. Pick a 3–8 word title summarizing the entry.

## Work-specific overrides

Work-specific preferences (paths, conventions, internal tooling) live in a
separate private file that is only present on work machines. If it exists,
load it:

@~/.claude/CLAUDE.work.md
