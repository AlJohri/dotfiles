---
name: spr
description: 'Stacked-PR workflow with spr (spacedentist/spr) — where each commit is one PR. Use for ANY spr operation: spr diff / spr diff --all, editing a published stack (fixup+autosquash to preserve the "Pull Request:" trailer), syncing commit messages, rebasing/restacking onto main, landing PRs, and reconciling after a merge. Covers why NOT to spr land as a repo admin (it bypasses branch protection) and the GitHub-UI merge + reconcile loop, plus manual auth setup and common gotchas.'
user_invocable: true
---

# spr — stacked PR workflow

spr (`spacedentist/spr`, the vetted tool) turns a line of commits on local
`main` into a stack of PRs: **one commit = one PR**, identity carried by the
`Pull Request:` trailer spr stamps into the commit message on first
`spr diff`. Docs: <https://spacedentist.github.io/spr/>; source for deep
questions in `~/.cargo/registry/src/index.crates.io-*/spr-*/` (`src/commands/`).

Always pass `--draft` to `spr diff` (publishes immediately, no dry-run;
drafts limit blast radius — no auto-reviewers).

## Mental model

- Commit everything to local `main` (or a branch); each commit becomes a PR.
- **Synthetic base branches:** a stacked PR targets `spr/<user>/main.<slug>`
  (= main + the lower commits), NOT `main`, so its diff shows only that one
  commit's changes. spr **never demotes** a PR back to a literal `main` base
  once it has a synthetic one; it just keeps that branch's contents in sync.
  Consequence: a stacked PR is **not** UI-mergeable as-is (see Landing).

## Finding a commit's PR (don't key off the branch)

Your local branch name is **not** any PR's head ref — spr publishes each commit
to a synthetic `spr/<user>/...` head branch. So `gh pr view` /
`gh pr list --head <branch>` from the working branch returns **nothing**, and
any tool that "detects the PR from the current branch" (e.g. `/review-comments`)
will wrongly conclude there's no PR. The commit→PR mapping lives **only** in the
`Pull Request:` line of each commit message. **Do NOT read it with git's
`%(trailers)` machinery — it returns empty 100% of the time here.** spr's key is
`Pull Request` (with a *space*), and git's trailer parser rejects any
whitespace-containing key, so `git log --format='%(trailers:key=Pull Request)'`
*never* matches. spr reads the same line with its own parser
(`message.rs`: `parse_message` uses `^\s*([\w\s]+?)\s*:\s*(.*)$` — `[\w\s]+`
deliberately allows spaces in the key). So scan the raw line yourself with
`grep`/`sed`, the way spr does — a plain `key: value` scan, not a git trailer:
```bash
# PR number for HEAD's commit
git log -1 --format='%B' | sed -n 's#^Pull Request: .*/pull/##p'
# every PR in the current stack, bottom→top
git log --reverse --format='%B' origin/main..HEAD | sed -n 's#^Pull Request: .*/pull/##p'
```
When a skill/command asks for a PR number on an spr stack, resolve it this way
and pass it explicitly rather than relying on branch detection.

## Adopting an existing PR into the stack

To attach a commit to a **PR that already exists** (one created manually with
`gh pr create`, or one spr lost track of) instead of opening a new one, add a
`Pull Request:` section to that commit's message. On the next `spr diff` spr
reads it, matches the existing PR, and **updates** it (pushes the commit's
content to that PR's head branch, fixes its base) rather than creating a
duplicate. The field accepts a bare number or the full URL — spr normalizes to
the URL:
```
Pull Request: 563
Pull Request: #563
Pull Request: https://github.com/<owner>/<repo>/pull/563   # owner/repo must match config
```
- Add it **preserving the rest of the message** — reword (non-HEAD recipe
  below) or fixup, NEVER `--amend -m` (drops the section, see Editing).
- **The PR keeps its existing head branch name.** spr force-pushes the commit
  there; it does NOT rename a manually-created head to `spr/<user>/…`. So an
  adopted PR can sit on a plain branch (e.g. `my-feature`) forever while still
  being fully spr-managed — that's expected, not breakage.
- **No message validation on adopted commits** — spr only runs
  `validate_commit_message` (test-plan etc.) when the commit has *no* PR number,
  so adoption never trips `requireTestPlan`.
- **The PR's GitHub body is preserved.** If it's richer than the commit message
  spr prints "Pull Request's title/message differ" and moves on — it does NOT
  overwrite unless you pass `--update-message`. Don't blindly `--update-message`
  (it clobbers a hand-written PR body; read the body first).
- The PR must be **open**; spr errors on a closed PR (remove the section to open
  a fresh one).

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
current **bottom** PR. Steps 1, 2, 4 are fine to do **automatically**; step 3
(the actual merge) is the user's manual UI action.
```bash
# 1. reconcile to latest main  [auto]
git fetch origin && git rebase origin/main && spr diff --all --draft -m "restack"
# 2. point ONLY the bottom PR at main (sticky; its diff = just its own commit).  [auto]
#    optional pre-merge peek: gh pr diff <bottom> --name-only
gh pr edit <bottom> --base main      # dismisses stale approvals — see below
# 3. squash-merge <bottom> in the GitHub UI  [MANUAL — user only]
# 4. drop the merged commit + restack the rest  [auto]
git fetch origin && git rebase origin/main      # "skipped previously applied commit …"
spr diff --all --draft -m "restack after #N landed"
```
Repeat for the next bottom. After a post-merge restack (step 4), re-pointing
the **new** bottom's base to main (step 2) is automatic too — only the UI merge
and `gh pr ready` are manual. **Do NOT** re-point the whole stack to `main` at
once — upper PRs would then show cumulative diffs and could merge the commits
beneath them. Why step 2 is needed: a stacked PR's base is the synthetic
branch, so a UI merge would otherwise merge into *that*, not `main`.

> **Restacking + landing dismisses approvals** (normal — just re-request).
> Both the base change (always) and the `spr diff` force-push (where
> `dismiss_stale_reviews_on_push: true`, common) count as stale-review
> triggers. So if main requires approvals, the bottom PR lands as
> `BLOCKED`/`REVIEW_REQUIRED` and needs a fresh approval; re-pointing the base
> back does NOT restore dismissed reviews. Just re-request the review.

### `spr land` mechanics (REFERENCE ONLY — do not use)

> 🚫 **Never `spr land` in this user's workflow.** They're an admin/bypass actor
> on these repos, so it would merge past branch protection (see warning above).
> Always merge via the GitHub UI. The mechanics below are documentation only.

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
- `spr land` won't merge a **draft** (GitHub blocks it). **Never run
  `gh pr ready` yourself** — marking a PR ready is always a manual user action.
  Surface that the PR is a draft and let the user promote it.

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

- Local branch ≠ PR head ref → `gh pr view`/`--head` finds no PR; map via the
  `Pull Request:` line, scanned with `sed`/`grep`
  (`git log -1 --format='%B' | sed -n 's#^Pull Request: .*/pull/##p'`). NOT git
  `%(trailers)` — spr's key has a space, which git's trailer parser rejects, so
  `%(trailers:key=Pull Request)` is always empty (spr uses its own `[\w\s]+:` parse).
- `--amend -m` on a published commit → orphaned/duplicate PR (drops trailer).
- Plain `spr diff` / `spr diff --update-message` → HEAD-only; use `--all`.
- `IO error: not a terminal` → pass `-m "…"`.
- Dropped commit → zombie PR → `spr close`.
- `spr land` as admin → silently bypasses CI/threads → merge via UI instead.
- Stacked PR base is synthetic → not UI-mergeable until `gh pr edit --base main`.
- Restack/land dismisses approvals (base change always; force-push where
  `dismiss_stale_reviews_on_push: true`) → bottom PR lands `BLOCKED`; re-request review.
- Per-commit checks → loop detached checkouts, not `rebase --exec`.
