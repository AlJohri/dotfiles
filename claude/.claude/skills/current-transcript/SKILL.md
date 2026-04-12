---
name: current-transcript
description: Show the file path to the current conversation's transcript JSONL file.
user_invocable: true
---

# Current Transcript

Show the file path to the current conversation's transcript JSONL file.

## Steps

### 1. Find the transcript

Claude Code stores transcripts at `~/.claude/projects/<project-dir>/<session-id>.jsonl` where `<project-dir>` is the absolute working directory path with `/` replaced by `-`.

Run these as **separate** bash commands (not chained), checking each result before proceeding.

First, derive the project directory and find the most recent transcript:

```bash
project_dir=$(echo "$PWD" | sed 's|/|-|g')
ls -t "$HOME/.claude/projects/${project_dir}"/*.jsonl 2>/dev/null | head -1
```

If the `ls` output is empty or the command fails, tell the user no transcript was found and show the project directory path so they can debug. **Do not proceed to step 2.**

### 2. Extract session metadata

Only run this after confirming step 1 returned a valid file path. Pass the **full path from step 1** as a literal string (do not rely on shell variables from a previous command):

```bash
python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    for line in f:
        d = json.loads(line)
        sid = d.get('sessionId', '')
        ts = d.get('timestamp', '')
        cwd = d.get('cwd', '')
        if sid and ts and cwd:
            print(f'Session ID: {sid}')
            print(f'Started:    {ts}')
            print(f'CWD:        {cwd}')
            break
" "/full/path/from/step1.jsonl"
```

### 3. Present the result

Show the user:
- **Transcript path** (the full path to the `.jsonl` file)
- **Session ID**
- **Started** timestamp
- **Resume command**: `claude --resume <session-id>`
