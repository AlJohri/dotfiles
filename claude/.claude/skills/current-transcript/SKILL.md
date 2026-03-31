---
name: current-transcript
description: Show the file path to the current conversation's transcript JSONL file.
user_invocable: true
---

# Current Transcript

Show the file path to the current conversation's transcript JSONL file.

## Steps

### 1. Determine the project directory

Claude Code stores transcripts under `~/.claude/projects/<project-dir>/` where `<project-dir>` is the absolute working directory path with `/` replaced by `-`.

Derive the project directory from the current working directory:

```bash
project_dir=$(echo "$PWD" | sed 's|/|-|g')
transcript_base="$HOME/.claude/projects/${project_dir}"
```

### 2. Find the most recently modified transcript

The current session's transcript is the most recently modified `.jsonl` file in the project directory (excluding `subagents/`):

```bash
transcript=$(ls -t "${transcript_base}"/*.jsonl 2>/dev/null | head -1)
```

### 3. Extract session metadata

Parse the first line of the transcript to get the session ID and timestamp:

```bash
python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    for line in f:
        d = json.loads(line)
        sid = d.get('sessionId', '')
        ts = d.get('timestamp', '')
        cwd = d.get('cwd', '')
        if sid:
            print(f'Session ID: {sid}')
            print(f'Started:    {ts}')
            print(f'CWD:        {cwd}')
            break
" "$transcript"
```

### 4. Present the result

Show the user:
- **Transcript path** (the full path to the `.jsonl` file)
- **Session ID**
- **Started** timestamp
- **Resume command**: `claude --resume <session-id>`
