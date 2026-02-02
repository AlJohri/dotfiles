---
name: review-copilot
description: Analyze and address Copilot code review comments on a PR.
user_invocable: true
---

# Review Copilot Comments

Review and address unresolved Copilot code review comments on a GitHub PR.

> **IMPORTANT — GraphQL & the Bash tool:** The Bash tool interprets `$` signs
> even inside single quotes, which breaks GraphQL variables like `$owner`.
> **Always write GraphQL queries to a temp file first**, then pass them with
> `-F query=@"$FILE"`. Never use `-f query='...'` with inline GraphQL.

## Phase 1: Fetch unresolved review threads

- Accept an optional argument: a PR number (e.g. `123`), a PR URL (e.g. `https://github.com/owner/repo/pull/123`), or no argument. When no argument is provided, detect the PR from the current branch with `gh pr view --json number -q .number`.
- Extract the repo owner and name from `gh repo view --json owner,name`.
- Use `gh api graphql` to fetch **all** review threads, paginating with cursors until `hasNextPage` is false. **Note:** GitHub's GraphQL API does not support server-side filtering by `isResolved` — all threads must be fetched and filtered client-side via `jq`. Use this query:

```graphql
query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        nodes {
          id
          isResolved
          comments(first: 50) {
            nodes {
              id
              databaseId
              author { login }
              body
              path
              line
              url
            }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
```

- The GraphQL response can be large (40KB+), which will get truncated by the Bash tool. To avoid this, save each page's response to a temporary file and use `jq` to merge and filter.
- **Critical:** Write the GraphQL query to a temp file first, then reference it with `-F query=@"$QUERY_FILE"`. Do NOT pass the query inline — `$` signs in GraphQL variables will be corrupted by bash.

Use this exact pagination loop:

```bash
# Step 1: Write the GraphQL query to a temp file (avoids $ escaping issues)
QUERY_FILE=$(mktemp)
cat > "$QUERY_FILE" << 'GRAPHQL'
query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        nodes {
          id
          isResolved
          comments(first: 50) {
            nodes {
              id
              databaseId
              author { login }
              body
              path
              line
              url
            }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}
GRAPHQL

# Step 2: Pagination loop — fetch all pages into temp files, then merge
TMPDIR_PAGES=$(mktemp -d)
CURSOR=""
PAGE=0

while true; do
  PAGE=$((PAGE + 1))
  if [ -n "$CURSOR" ]; then
    gh api graphql \
      -F query=@"$QUERY_FILE" \
      -f owner="$OWNER" -f repo="$REPO" -F pr="$PR_NUMBER" \
      -f cursor="$CURSOR" > "$TMPDIR_PAGES/page_$PAGE.json"
  else
    gh api graphql \
      -F query=@"$QUERY_FILE" \
      -f owner="$OWNER" -f repo="$REPO" -F pr="$PR_NUMBER" \
      > "$TMPDIR_PAGES/page_$PAGE.json"
  fi

  HAS_NEXT=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' "$TMPDIR_PAGES/page_$PAGE.json")
  CURSOR=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' "$TMPDIR_PAGES/page_$PAGE.json")

  if [ "$HAS_NEXT" != "true" ]; then
    break
  fi
done

# Step 3: Merge all pages and filter client-side to unresolved Copilot threads
jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | select(.comments.nodes[0].author.login == "copilot-pull-request-reviewer")
  | {
      threadId: .id,
      databaseId: .comments.nodes[0].databaseId,
      body: .comments.nodes[0].body,
      path: .comments.nodes[0].path,
      line: .comments.nodes[0].line,
      url: .comments.nodes[0].url
    }]' "$TMPDIR_PAGES"/page_*.json
```

- For each thread, store: thread ID, comment `databaseId` (for REST API calls), body, file path, line number, and URL.
- If no unresolved Copilot comments are found, report that and stop.

## Phase 2: Analyze each comment

For each unresolved Copilot comment, launch a **Task sub-agent** (using the Task tool with `subagent_type="general-purpose"`) to do the heavyweight research. The sub-agent should:

1. Read the relevant source file and surrounding context (at least 20 lines around the mentioned line).
2. Research the claim — use web searches and documentation to verify whether Copilot's suggestion is correct, partially correct, or wrong.
3. Determine the best course of action. Even if Copilot is wrong, consider whether the code could be clearer to avoid confusing future LLM reviewers or human readers.
4. Return its findings: a summary of what Copilot said, whether it's correct, and a recommended action.

After the sub-agent returns, present findings to the user via `AskUserQuestion` **one comment at a time**. Each question must include:
- The **verbatim Copilot comment body** so the user can read the original suggestion
- The **relevant code snippet** (20+ lines of surrounding context) so the user can see the code in question
- The **sub-agent's research findings** summarizing correctness and recommendation

Offer these options:
- **Apply Copilot's suggestion** — if the suggestion is valid as-is
- **Apply a modified fix** — describe what you'd change and why
- **Add a clarifying comment/docs** — Copilot is wrong but the code is ambiguous
- **Skip for now** — defer this comment, leave it unresolved

Collect user decisions for all comments before proceeding to fixes.

## Phase 3: Execute fixes

1. Apply all chosen fixes to the codebase.
2. Stage the specific changed files by name (do NOT use `git add -A` or `git add .`).
3. Create a single commit with a descriptive message summarizing the changes. If the user prefers, split into one commit per logical group.
4. Push the commit(s) to the current branch.

## Phase 4: Respond and resolve

For each addressed comment:

1. Reply to the review comment using the REST API:
   ```
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_database_id}/replies -f body="<message>"
   ```
   The reply should include:
   - A brief explanation of how the comment was addressed
   - A link to the commit: `https://github.com/{owner}/{repo}/commit/{sha}`

2. Resolve the review thread using GraphQL. **Write the mutation to a temp file** (same `$` escaping issue as Phase 1):
   ```bash
   RESOLVE_QUERY_FILE=$(mktemp)
   cat > "$RESOLVE_QUERY_FILE" << 'GRAPHQL'
   mutation($threadId: ID!) {
     resolveReviewThread(input: { threadId: $threadId }) {
       thread { isResolved }
     }
   }
   GRAPHQL

   gh api graphql -F query=@"$RESOLVE_QUERY_FILE" -f threadId="$THREAD_ID"
   ```

For skipped comments: do nothing — leave them unresolved and don't reply.
