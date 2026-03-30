---
name: find-conversation
description: Search past Claude Code conversation transcripts to find old sessions by keyword, topic, or phrase.
user_invocable: true
---

# Find Conversation

Search past Claude Code conversation transcripts to find old sessions by keyword, topic, or phrase.

## Usage

The user provides a search query describing what they're looking for (e.g. "merge incidents script", "kubernetes deployment fix", "refactoring auth middleware").

## Steps

### 1. Search history.jsonl first

The file `~/.claude/history.jsonl` contains one JSON line per user message across all sessions, with fields `display` (the message text), `project`, `sessionId`, and `timestamp`. This is the fastest way to find a session.

```bash
rg -i "<pattern>" ~/.claude/history.jsonl --no-line-number
```

Parse matches with Python to extract `sessionId`, `project`, `display`, and `timestamp`:

```bash
rg -i "<pattern>" ~/.claude/history.jsonl --no-line-number | python3 -c "
import json, sys
from datetime import datetime
seen = set()
for l in sys.stdin:
    d = json.loads(l.strip())
    sid = d.get('sessionId', '')
    if sid in seen:
        continue
    seen.add(sid)
    ts = datetime.fromtimestamp(d['timestamp']/1000).strftime('%Y-%m-%d %H:%M') if 'timestamp' in d else '?'
    print(f'[{ts}] Session: {sid}')
    print(f'  Project: {d.get(\"project\",\"?\")}')
    print(f'  Message: {d.get(\"display\",\"\")[:200]}')
    print()
"
```

### 2. If history.jsonl doesn't have enough results, search transcript files

Transcripts are stored as JSONL files at:
```
~/.claude/projects/*/UUID.jsonl
```

Search across all of them (excluding subagent transcripts):

```bash
rg -il "<pattern>" ~/.claude/projects/ -g "*.jsonl" --no-messages 2>/dev/null | grep -v subagents
```

To rank results by relevance, count matches per file:

```bash
rg -il "<pattern>" ~/.claude/projects/ -g "*.jsonl" --no-messages 2>/dev/null | grep -v subagents | while read f; do
  count=$(rg -c "<pattern>" "$f" 2>/dev/null || echo 0)
  echo "$count $f"
done | sort -rn | head -10
```

### 3. Preview conversation content

Once you have a candidate file, extract human/user messages to show the user what the conversation was about:

```bash
python3 -c "
import json, sys
with open(sys.argv[1]) as fh:
    for i, line in enumerate(fh):
        d = json.loads(line)
        msg = d.get('message', {})
        role = msg.get('role', '')
        content = msg.get('content', '')
        text = ''
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            for b in content:
                if isinstance(b, dict) and b.get('type') == 'text':
                    text += b['text']
        if role in ('user', 'human') and text.strip() and len(text.strip()) > 10:
            print(f'[msg {i}] {text[:200]}')
" <file_path> | head -20
```

### 4. Present results to the user

For each matching session, show:
- **Date** (from timestamp)
- **Project** directory
- **Session ID**
- **Matching message snippet(s)**
- The resume command: `claude --resume <session-id>`

## Search tips

- Start with `history.jsonl` — it's a single file and very fast to search.
- Use multiple patterns if the first is too broad (e.g. `merge.*incident` instead of just `merge`).
- If searching transcript files, exclude `subagents/` directories — they contain internal tool calls, not user conversations.
- Message content in transcripts can be a string or an array of content blocks — always handle both formats.
- The `role` field may be `user` or `human` depending on the message type.
