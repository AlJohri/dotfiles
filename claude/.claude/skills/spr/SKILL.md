---
name: spr
description: Stacked-PR workflow with spr (spacedentist/spr) — where each commit is one PR. Use for ANY spr operation: spr diff / spr diff --all, editing a published stack (fixup+autosquash to preserve the "Pull Request:" trailer), syncing commit messages, rebasing/restacking onto main, landing PRs, and reconciling after a merge. Covers why NOT to spr land as a repo admin (it bypasses branch protection) and the GitHub-UI merge + reconcile loop, plus manual auth setup and common gotchas.
user_invocable: true
---

# spr — stacked PR workflow

spr (`spacedentist/spr`, the vetted tool) turns a line of commits on local
`main` into a stack of PRs: **one commit = one PR**, identity carried by the
`Pull Request:` trailer spr stamps into the commit message on first
`spr diff`. Docs: <https://spacedentist.github.io/spr/>; source for deep
questions in `~/.cargo/registry/src/index.crates.io-*/spr-*/` (`src/commands/`).

Always pass `--draft` to `spr diff` (publishes immediately, no dry-run;
drafts limit blast radius — no auto-reviewers, CI often skipped).

## Mental model

- Commit everything to local `main` (or a branch); each commit becomes a PR.
- **Synthetic base branches:** a stacked PR targets `spr/<user>/main.<slug>`
  (= main + the lower commits), NOT `main`, so its diff shows only that one
  commit's changes. spr **never demotes** a PR back to a literal `main` base
  once it has a synthetic one; it just keeps that branch's contents in sync.
  Consequence: a stacked PR is **not** UI-mergeable as-is (see Landing).

## Editing a published stack

- Edit with **fixup + autosquash**, NEVER `git commit --amend -m` — `-m`
  drops the `Pull Request:` trailer and spr orphans/duplicates the PR.
  `--amend --no-edit` keeps the trailer; `--amend -F file` is safe only if the
  file includes the trailer line.
  ```bash
  git commit --fixup=<sha>
  GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main
  ```
- **Reword a non-HEAD commit non-interactively:** flip its todo line to
  `reword` by SHA and supply the message via `GIT_EDITOR`:
  ```bash
  GIT_SEQUENCE_EDITOR='sed -i -E "s/^pick <sha>/reword <sha>/"' \
  GIT_EDITOR='cp /tmp/msg.txt' git rebase -i origin/main
  ```
  (`GIT_SEQUENCE_EDITOR` swaps the interactive editor for any non-interactive
  command — see also the `exec` recipe under Landing.)

## Publishing / updating

- `spr diff` only operates on **HEAD** (one PR). Publish/refresh the **whole
  stack** with **`spr diff --all --draft`** — required after any rebase (which
  re-SHAs every commit).
- When a commit changed, `spr diff` opens `$EDITOR` for an update message and
  dies in a non-TTY (`IO error: not a terminal`) — always pass `-m "…"`.
- `--update-message` (push a changed commit *message* to its PR body) is **also
  HEAD-only**. To sync a **non-HEAD** commit's message, pair with `--all`:
  `spr diff --all --update-message --draft -m "…"`. Plain
  `spr diff --update-message` silently skips middle commits.

### Before publishing a stack: per-commit sweep

Each commit is its own PR and is CI'd **alone**, so check every commit, not
just the tip. Run per-commit checks by **looping detached checkouts**, NOT
`git rebase --exec` — `--exec` re-SHAs the whole stack and forces a needless
re-push. (Per-repo CLAUDE.md defines the exact gate commands; the *pattern* is:
fmt/lint/build each commit in `origin/main..HEAD`, full lint+test once at tip.)

## Rebasing the whole stack onto new main

The big payoff of commits-on-main: restacking is one rebase + one publish.
```bash
git fetch origin && git rebase origin/main   # resolve conflicts once
spr diff --all --draft -m "restack"
```
Dropping a commit leaves a **zombie open PR** — close it with `spr close`.

## Landing

### ⚠️ Do NOT `spr land` as a repo admin / bypass actor

`spr land` does **not** enforce branch protection — it checks only GitHub's
`mergeable` (merge-*conflict*) flag, then calls the squash-merge API and lets
**GitHub** decide. Required-checks / thread-resolution live in
`mergeStateStatus`, which spr ignores. So if your token is an **admin** or a
**bypass actor on a bypassable ruleset**, `spr land` will **merge past red CI
and unresolved threads** — it's the Merge button with bypass power. There is
**no spr/merge-API flag** to "merge without bypassing"; the only controls are
GitHub-side (ruleset `bypass_actors`, "do not allow bypassing") or landing
under a non-bypass identity. **If the gates must hold, merge via the GitHub UI
instead.** (Per-repo CLAUDE.md may forbid `spr land` outright — check it.)

### Recommended: merge via GitHub UI, bottom-up, one PR at a time

Preserves isolated per-PR diffs and respects branch protection. For the
current **bottom** PR:
```bash
# 1. reconcile to latest main
git fetch origin && git rebase origin/main && spr diff --all --draft -m "restack"
# 2. point ONLY the bottom PR at main (sticky; its diff = just its own commit).
#    optional pre-merge peek: gh pr diff <bottom> --name-only
gh pr edit <bottom> --base main
# 3. squash-merge <bottom> in the GitHub UI
# 4. drop the merged commit + restack the rest
git fetch origin && git rebase origin/main      # "skipped previously applied commit …"
spr diff --all --draft -m "restack after #N landed"
```
Repeat for the next bottom. **Do NOT** re-point the whole stack to `main` at
once — upper PRs would then show cumulative diffs and could merge the commits
beneath them. Why step 2 is needed: a stacked PR's base is the synthetic
branch, so a UI merge would otherwise merge into *that*, not `main`.

### `spr land` mechanics (when it IS appropriate — non-admin/non-bypass)

- It lands **HEAD**, and refuses unless `git rev-list master..HEAD` is exactly
  one commit (`Cannot land a commit whose parent is not on master`). So on a
  multi-commit stack, plain `spr land` lands nothing.
- To land the **bottom**, use an interactive rebase that makes it momentarily
  HEAD-on-master (per spr `docs/user/stack.md`). Fully programmatic:
  ```bash
  GIT_SEQUENCE_EDITOR='sed -i "1a exec spr land"' git rebase -i origin/main
  ```
  (line 1 of the todo is the bottom commit). On success spr squash-merges via
  API (re-pointing the base to master first), deletes the PR's head+base
  branches, and **auto-rebases the remaining commits**; then run
  `spr diff --all` to update the other PRs. A failed `exec` pauses the rebase
  (`git rebase --continue`/`--abort`).
- `git rebase origin/main -x 'spr land'` (exec after *every* pick) attempts the
  whole stack bottom-up — master advances between lands so the parent check
  passes — but it's readiness-gated and undocumented; prefer one targeted exec.
- `spr land --cherry-pick` only applies to PRs created with
  `spr diff --cherry-pick` (independent, non-synthetic base) — not the default
  stacked flow.
- `spr land` won't merge a **draft** (GitHub blocks it) — `gh pr ready` first.

## Setup / auth (manual — `spr init` is often org-blocked)

`spr init`'s device-flow OAuth App is frequently blocked by an org's OAuth-App
restrictions. Configure manually in the repo's `.git/config` (local; shared
across all worktrees), reusing `gh`'s already-approved token:
```bash
git config spr.githubAuthToken "$(gh auth token)"   # snapshot, not live — re-run on rotation
git config spr.githubRepository <owner>/<repo>
git config spr.githubMasterBranch <main>
git config spr.githubRemoteName origin
git config spr.branchPrefix 'spr/<user>/'
git config spr.requireTestPlan false
```

## Quick gotcha index

- `--amend -m` on a published commit → orphaned/duplicate PR (drops trailer).
- Plain `spr diff` / `spr diff --update-message` → HEAD-only; use `--all`.
- `IO error: not a terminal` → pass `-m "…"`.
- Dropped commit → zombie PR → `spr close`.
- `spr land` as admin → silently bypasses CI/threads → merge via UI instead.
- Stacked PR base is synthetic → not UI-mergeable until `gh pr edit --base main`.
- Per-commit checks → loop detached checkouts, not `rebase --exec`.
