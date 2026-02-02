---
name: yeet
description: Create a branch, commit, push, and open a draft PR from the current session's changes.
user_invocable: true
---

# Yeet

Create a branch, commit all current session changes, push, and open a draft PR — all automatically.

## Steps

1. **Analyze session context** — Review what was changed in this session and why. Use `git status` and `git diff` to understand the scope of changes.

2. **Generate a branch name** — Create a short, descriptive slug based on the changes (e.g. `fix-login-redirect`, `add-user-auth`). Do not use a `yeet` prefix.

3. **Create & switch to the branch** — Run `git checkout -b <branch-name>` from the current HEAD.

4. **Stage relevant files** — Stage specific files that were changed in the session. Do NOT use `git add -A` or `git add .`. Add files by name.

5. **Generate a commit message** — Write a concise, conventional commit message summarizing the changes based on session context.

6. **Commit** — Run `git commit` with the generated message.

7. **Push** — Run `git push -u origin <branch-name>`.

8. **Create a draft PR** — Run `gh pr create --draft` targeting the repo's default branch. Auto-generate a title and body summarizing the changes. Return the PR URL to the user.
