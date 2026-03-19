---
name: incident-io-update
description: Post a status update to an incident.io incident using the internal web app API via browser cookies
user_invocable: false
---

## When to use this skill

Use this when the user asks you to post an update on an incident.io incident. The `create_incident_update` MCP tool is broken (returns 404), so use this script instead.

## Usage

```bash
incident-io-update <incident_ref> "<message>" [--severity NAME] [--status-id ID]
```

`<incident_ref>` accepts the opaque ID (`01ABCDEFGHIJKLMNOPQRSTUVWX`) or the human-readable reference (`INC-123`).

## Step-by-step

1. **Find the incident** — use `list_incidents` or `get_incident` MCP tools. The script accepts either the human-readable reference (`INC-123`) or the opaque ID (`01ABCDEFGHIJKLMNOPQRSTUVWX`) from the `permalink` URL.

2. **Confirm the message with the user** — show the exact text you plan to post and wait for approval before running the script.

3. **Run the script** — no env var needed, the org ID is derived automatically from browser cookies:
   ```bash
   incident-io-update INC-123 "Your update message here"
   incident-io-update INC-123 "Escalating severity" --severity major
   ```

4. **Check the output** — the script prints the updated status, severity, and timestamp on success.

## Notes

- Requires Chrome to be logged into `app.incident.io`
- If cookie extraction fails, the user needs to log in to incident.io in Chrome first
- `--severity` accepts names like `minor`, `major`, `critical` (case-insensitive); omitting it preserves the current severity
- `--status-id` is optional — omitting it preserves the current status
- The org ID is derived automatically via `GET /api/identity/self`; override with `INCIDENT_IO_ORG_ID` env var if needed
