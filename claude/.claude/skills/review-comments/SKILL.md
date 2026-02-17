---
name: review-comments
description: Analyze and address all review comments on a PR.
user_invocable: true
---

# Review PR Comments

Review and address all unresolved review comments on a GitHub PR.

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

# Step 3: Merge all pages and filter client-side to unresolved threads (all authors)
# Capture the FULL conversation in each thread, not just the first comment
jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | {
      threadId: .id,
      path: .comments.nodes[0].path,
      line: .comments.nodes[0].line,
      url: .comments.nodes[0].url,
      lastCommentDatabaseId: .comments.nodes[-1].databaseId,
      comments: [.comments.nodes[] | {
        author: .author.login,
        body: .body,
        databaseId: .databaseId,
        url: .url
      }]
    }]' "$TMPDIR_PAGES"/page_*.json
```

- For each thread, store: thread ID, file path, line number, URL, the `databaseId` of the **last** comment (for replying via REST API), and the **full list of comments** with author, body, databaseId, and URL.
- If no unresolved threads are found, report that and stop.

## Phase 2: Analyze each thread

Each thread is a conversation — reviewers often clarify, retract, or refine their feedback in follow-up comments. Analyze the **entire thread** as a unit, not individual comments.

For each unresolved thread, launch a **Task sub-agent** (using the Task tool with `subagent_type="general-purpose"`) to do the heavyweight research. The sub-agent should:

1. Read the **full thread conversation** to understand the arc of the discussion — an initial concern may be answered, clarified, or withdrawn by later comments.
2. Read the relevant source file and surrounding context (at least 20 lines around the mentioned line).
3. Determine what the thread's **current ask** is. Often the last comment changes the nature of the request (e.g., an initial objection followed by "Oh wait, I see — this is fine" means there may be nothing to fix).
4. Research any remaining claims — use web searches and documentation to verify correctness.
5. Return its findings: a summary of the thread discussion, what (if anything) still needs to be addressed, and a recommended action.

After the sub-agent returns, present findings to the user via `AskUserQuestion` **one thread at a time**. Each question must include:
- The **full thread conversation** rendered as a quoted discussion, showing each comment with its author, so the user can follow the back-and-forth (e.g., `> **@reviewer:** I think we're missing s3Bucket here?` / `> **@reviewer:** Oh wait I understand now...`)
- A link to the thread on GitHub
- The **relevant code snippet** (20+ lines of surrounding context) so the user can see the code in question
- The **sub-agent's analysis** summarizing the discussion arc and what (if anything) still needs action

Offer these options:
- **Apply a fix** — describe what you'd change based on the thread's conclusion
- **Reply only** — no code change needed, but respond to the thread to acknowledge or clarify
- **Add a clarifying comment/docs in code** — the code is correct but the thread shows it's confusing
- **Skip for now** — defer this thread, leave it unresolved

Collect user decisions for all threads before proceeding to fixes.

## Phase 3: Execute fixes

1. Apply all chosen fixes to the codebase.
2. Stage the specific changed files by name (do NOT use `git add -A` or `git add .`).
3. Create a single commit with a descriptive message summarizing the changes. If the user prefers, split into one commit per logical group.
4. Push the commit(s) to the current branch.

## Phase 4: Respond and resolve

For each addressed thread:

1. Reply to the **last comment** in the thread using the REST API (use `lastCommentDatabaseId` from Phase 1):
   ```
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{last_comment_database_id}/replies -f body="<message>"
   ```
   The reply should include:
   - A brief explanation of how the thread was addressed
   - A link to the commit if code was changed: `https://github.com/{owner}/{repo}/commit/{sha}`

2. **Resolve only bot-authored threads (e.g., Copilot).** If the thread was opened by a bot (check if the author login ends with `[bot]` or is `copilot`), resolve it automatically using GraphQL. **Write the mutation to a temp file** (same `$` escaping issue as Phase 1):
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

   **Do NOT auto-resolve threads opened by human reviewers.** The human should verify the fix and resolve it themselves. Leave the thread unresolved after replying so they retain the opportunity to confirm the change is satisfactory.

For skipped threads: do nothing — leave them unresolved and don't reply.
