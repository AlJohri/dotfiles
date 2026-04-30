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

I use bare git repositories with all work done in git worktrees. The bare repo root has no working tree — only `.git/` and `.claude/`.

**Directory layout:**
```
<repo>/                              # bare repo (no working tree)
<repo>/.claude/worktrees/main/       # main branch worktree (always exists)
<repo>/.claude/worktrees/<name>/     # feature/task worktrees
```

**Rules:**
- Never edit files in the bare repo root. If the session starts in a bare repo root, call `EnterWorktree` before making any changes.
- To start a new task/branch, use `EnterWorktree` to create a fresh worktree. If already inside a worktree, first `cd` to the bare repo root (e.g., `cd "$(git rev-parse --path-format=absolute --git-common-dir | sed 's/\.git$//')"`) before calling `EnterWorktree`.
- To switch to an existing worktree (e.g., `main`), use `cd` to navigate to it directly.
- The worktree name must match the branch name exactly (e.g., branch `fix-auth-timeout` → worktree name `fix-auth-timeout`). Pass the branch name as the `name` parameter to `EnterWorktree`.
- After entering a worktree, run `mise trust` if a `mise.toml` or `.mise.toml` exists.
- After entering a worktree, if a `.pre-commit-config.yaml` exists, ensure hooks are installed (see pre-commit instructions below).
- Never use `git checkout` or `git switch` to change branches. Always create a new worktree for the target branch and `cd` into it (or use `EnterWorktree`).

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
