# Global Preferences

## Workflow

- Always create pull requests as **drafts** (`gh pr create --draft`).
- Always start from a clean state before making changes. Investigate and fix pre-existing issues first so it's easy to distinguish new problems from pre-existing ones.
- Tackle problems head on — don't silently work around them. If an approach fails, investigate why and fix the root cause. Never silently switch to a workaround — always ask the user first if a workaround is acceptable and explain what you'd do differently.
- When writing PR descriptions, always base them on the **diff against the default branch** (usually `main`), not on intermediate commit messages. The description should describe the net effect of all changes, not retell the story of how you got there.
- Before updating a PR description, always read the current description first (`gh pr view`) to avoid overwriting manual edits or a more detailed description from a previous session.
- For `gh` commands with markdown bodies (PR/issue create/edit, comments): write the body via the Write tool and pass `--body-file <path>`. Heredoc-via-`--body` mangles backticks and dollar signs in markdown.
- **GitHub PR line comments** (`POST /repos/{o}/{r}/pulls/{n}/comments`) only attach to lines present in the PR's diff hunks. For renamed/moved files, GitHub detects the rename server-side and the diff only contains *modified* lines — **unchanged context that was merely moved is not commentable** and returns `422 "pull_request_review_thread.line could not be resolved"`. Before posting:
  1. Verify the PR's current base ref (`gh pr view <n> --json baseRefName,baseRefOid,headRefOid`) — base may have changed mid-session.
  2. For renamed files, diff the old path vs. new path (`git log --follow` to find the rename, then `git diff <main>:<old> <head>:<new>`) to see which lines actually changed in the PR. Only those lines accept comments.
  3. If a finding lands on unchanged-but-moved code, it's pre-existing — surface it to the user as a follow-up rather than trying to attach it to this PR.
- **Never post probe/test comments to a real PR to debug API behavior.** Always confirm commentable lines via local diff inspection first. If a probe is genuinely needed, ask the user before posting.
- To include screenshots in PR descriptions, upload them with `gh image <path> --repo <owner/repo>`, which outputs a markdown image reference (`![name](url)`). Paste the output directly into the PR body.
- If a `.pre-commit-config.yaml` exists, ensure hooks are installed (`pre-commit install`) before committing. If it fails with `core.hooksPath` error, unset it first (`git config --unset core.hooksPath`), then install — the hook goes to `.git/hooks/` which is already shared across worktrees. If installation still fails, fall back to `pre-commit run --all-files` explicitly. May need `mise trust` first in new worktrees.
- Skip optional, long-running validation stages locally (e.g., pre-commit `--hook-stage manual`, `make ci-full`, `tox -e all`). These stages are opt-out by design — they're slow (network fetches, full-repo templating, cross-cluster renders) and meant to be skipped during iteration. The default validation is what CI runs on every commit and is sufficient. If you need to exercise a specific expensive hook, run it targeted at just the changed files.

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
- **Prefer `gwt` over raw `git worktree`/`git checkout`/`git switch`.** `gwt` is a wrapper at `~/dotfiles/scripts/bin/gwt` (stowed to `~/bin/gwt`) that handles the bare-repo conventions, runs `mise trust` automatically (both for new and existing worktrees), and for Rust workspaces hardlinks registry-dep build artifacts from the base branch's worktree so the new worktree skips re-running `*-sys` build scripts on its first build. **Use it instead of issuing `git worktree add`, `git checkout <branch>`, or `git switch` directly.** The raw plumbing commands listed below are documented for reference / when you need behavior gwt doesn't expose.
- Do NOT use the `EnterWorktree` tool (it places worktrees under `.claude/worktrees/`, which is the wrong location for this layout).
- Never edit files in the bare repo root. If the session starts in a bare repo root, create or enter a worktree first.
- The worktree directory name must match the branch name exactly (branch `fix-auth-timeout` → directory `<repo>/fix-auth-timeout/`).

**Working with `gwt`:**
- `gwt` (no args) — list all worktrees with their branches and (if `gh` is available) linked PR numbers.
- `gwt <branch>` — if the branch exists (locally or on origin), create or enter the worktree for it. If it doesn't exist, create a new branch off the default branch (origin/HEAD, usually `main`). Returns the worktree path on stdout; the fish wrapper additionally `cd`s into it.
- `gwt <branch> <source-branch>` — create a new branch forked from `<source-branch>` (must already exist). Refuses if `<branch>` already exists. The hardlink step then sources from the `<source-branch>` worktree, which guarantees a Cargo.lock match.
- `gwt prune` — remove worktrees with missing directories and worktrees whose tracked upstream branch was deleted on the remote. Branches that were never pushed are kept (no upstream).
- Opt out of the hardlink step with `GWT_SKIP_LINK=1`.

**Raw git plumbing (only when gwt doesn't suffice):**
- To find the bare repo root from anywhere inside the repo:
  ```bash
  REPO_ROOT="$(git rev-parse --path-format=absolute --git-common-dir)"
  REPO_ROOT="${REPO_ROOT%/.git}"
  ```
- To create a worktree manually:
  ```bash
  git worktree add "$REPO_ROOT/<branch>" <branch>             # branch exists
  git worktree add -b <branch> "$REPO_ROOT/<branch>" main     # new branch off main
  ```
  After a manual `git worktree add`, you'll need to run `mise trust` yourself — that's exactly the kind of thing `gwt` automates.
- Never use `git checkout` or `git switch` to change branches. Always create a new worktree for the target branch and `cd` into it.

**After creating or entering a worktree (relevant whether you used `gwt` or raw git):**
- mise: `gwt` already runs `mise trust` for you. If you went around it, run `mise trust` from the worktree root yourself. mise walks parent directories looking for `mise.toml`, `mise.local.toml`, `.mise.toml`, `.mise.local.toml`, and `.config/mise.toml`; any of them — including in the bare-repo root above the worktree — must be trusted before mise will load it. If a build or env-dependent command fails with "Config files in ... are not trusted", the fix is `mise trust` (re-run from the worktree).
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
