# Global Preferences

## Workflow

- Always create pull requests as **drafts** (`gh pr create --draft`).
- Always start from a clean state before making changes. Investigate and fix pre-existing issues first so it's easy to distinguish new problems from pre-existing ones.
- Tackle problems head on — don't silently work around them. If an approach fails, investigate why and fix the root cause. Never silently switch to a workaround — always ask the user first if a workaround is acceptable and explain what you'd do differently.
- When writing PR descriptions, always base them on the **diff against the default branch** (usually `main`), not on intermediate commit messages. The description should describe the net effect of all changes, not retell the story of how you got there.
- Before updating a PR description, always read the current description first (`gh pr view`) to avoid overwriting manual edits or a more detailed description from a previous session.

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
