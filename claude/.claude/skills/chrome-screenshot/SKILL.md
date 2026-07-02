---
name: chrome-screenshot
description: 'Capture a screenshot of a live Chrome tab to a file on disk using the `chrome-shot` CLI, so the screenshot can be Read back (for documentation, worklogs, or PR descriptions). Use this INSTEAD of the claude-in-chrome MCP screenshot tools whenever you need the image as an actual file — the MCP returns an inline image it hands to the model and never writes to disk, so those screenshots cannot be Read, uploaded, or embedded. chrome-shot attaches to the user''s real running Chrome (real profile/session) via the DevTools Protocol and writes a PNG. Triggers: "screenshot the page/tab", "capture what''s on screen for the PR/worklog", "save a screenshot of the app", "add a before/after image to the PR".'
user_invocable: false
---

# chrome-screenshot — capture a Chrome tab to disk

`chrome-shot` (at `~/bin/chrome-shot`, a uv single-file script) screenshots a
**live tab in the user's already-running Chrome** — real profile, logged-in
session — and writes a PNG you can then `Read`, `gh image`-upload, or embed.

Reach for this whenever the screenshot needs to become a **file**. The
`mcp__claude-in-chrome__*` screenshot tools return an inline image to the model
and write nothing to disk, so their output can't be Read back or reused. This
tool exists to close that gap.

## Division of labor

- **Driving** (navigate, click, scroll, type) is the `claude-in-chrome` MCP or
  the user at the keyboard. `chrome-shot` does NOT drive.
- **Capture** is `chrome-shot`. It shares the same live Chrome, so it shoots
  whatever the driver navigated to — including tabs on other workspaces or
  minimized (CDP renders the DOM regardless of what's on screen).

## One-time prerequisite (per Chrome session)

`chrome-shot` needs Chrome 144+ consent-mode remote debugging enabled. If a
capture fails with a "DevToolsActivePort not found" message, ask the user to:

1. Open `chrome://inspect/#remote-debugging`.
2. Tick **"Allow remote debugging for this browser instance."**

The first capture after that spawns a detached background daemon holding one
CDP connection; Chrome shows an **"Allow remote debugging?"** dialog **once** —
the user clicks Allow. Every later capture reuses the daemon: ~0.3s, no prompt.
The toggle and daemon reset on Chrome restart (re-tick + re-Allow once).

## Usage

```bash
chrome-shot OUT --match SUBSTR        # tab whose title/URL contains SUBSTR
chrome-shot OUT --active              # the focused/visible tab
chrome-shot OUT --match SUBSTR --full # full scrollable page, not just viewport
chrome-shot --list                   # list open tabs (title + URL)
chrome-shot --stop                   # stop the daemon
```

- `OUT` is an explicit path you choose (there is no default dir / auto-naming).
  Always pass an absolute or project-relative path.
- Prefer `--match` (a URL/title substring) when you know the page — it's ~0.3s.
  Use `--active` right after the MCP navigates somewhere; it's ~2s because CDP
  has no focused-tab field so it probes every tab.
- After capturing, `Read` the file to actually see what was captured.

## Recipes

**Document a flow into a worklog** (MCP or user drives between shots):

```bash
D="$WORKLOGS/$(date +%Y-%m-%d)-billing/img"; mkdir -p "$D"
# (MCP navigates to /billing) then:
chrome-shot "$D/01-empty-cart.png" --active
# (MCP clicks "add item") then:
chrome-shot "$D/02-added-item.png" --active --full
```

**Screenshot for a PR/issue description** (upload is a separate step):

```bash
chrome-shot /tmp/before.png --match localhost:3000/billing --full
gh image /tmp/before.png --repo seltz-ai/console   # prints ![before](https://…)
```

Paste the `gh image` markdown into the PR/issue body (write the body to a file
and pass `--body-file`, per the global `gh` convention).

## Notes

- Captures page content only — never the OS window frame (tabs/URL bar). For the
  browser chrome itself you'd need a compositor tool (`grim`); for any page
  content this is strictly better and needs no active workspace.
- Auto-discovers the port from `~/.config/google-chrome/DevToolsActivePort`; no
  hardcoded port. Override with `--ws` / `--port-file` for a non-default profile.
