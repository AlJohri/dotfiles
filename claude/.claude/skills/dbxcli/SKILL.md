---
name: dbxcli
description: 'Query and manage Dropbox from the command line with dbxcli (dropbox/dbxcli). Use to authoritatively verify what is actually in the Dropbox CLOUD — independent of the local desktop app/File Provider — e.g. confirm a folder finished uploading, list/count/diff cloud files, download/upload, check account usage. Covers install, the interactive OAuth login (and headless token), and the big output-parsing gotchas (ls -R packs multiple files per line; du reports account usage, not folder size).'
user_invocable: false
---

# dbxcli — Dropbox from the CLI

`dbxcli` (`dropbox/dbxcli`) talks to the **Dropbox HTTP API directly**, i.e. to
Dropbox's servers — *not* the local desktop app's sync database. That's its
single most useful property: it gives the **authoritative, server-side truth**
about what is actually stored in the cloud, independent of whatever the local
Dropbox app claims. Reach for it whenever you need to independently *verify*
sync — a server-side query settles questions the local menu-bar status can't,
and that are easy to get wrong by eyeballing local state.

Latest release is v3.4.0; it still works and its built-in OAuth app key still
issues valid tokens. (The repo is **not** archived as of this writing — don't
assume it's dead.)

## Install

```bash
brew install dbxcli
# or a release binary: https://github.com/dropbox/dbxcli/releases
```

## Auth

First use needs OAuth. Two paths:

- **Interactive (normal):** `dbxcli login` prints a URL → open it, click Allow,
  copy the code, paste it back at the prompt. Token caches to
  `~/.config/dbxcli/auth.json` (one-time).
  - **You cannot drive this non-interactively.** It uses PKCE — each run mints a
    fresh `code_challenge`, so the URL must be opened from the *same* running
    `dbxcli login` process and the code pasted into *its* stdin. You can't
    capture the URL from one invocation and feed the code to another. If a human
    must do it, have them run `dbxcli login` themselves (e.g. an interactive
    shell), then you run read-only commands afterward against the cached token.
- **Headless:** export a token instead of logging in:
  ```bash
  export DBXCLI_ACCESS_TOKEN=<token>      # generate at dropbox.com/developers/apps
  ```
  Prefer this in CI/automation. Treat the token as a secret — don't echo it into
  logs or chat.

Confirm auth: `dbxcli account` (prints the logged-in account).

For the command list and exact argument order, run `dbxcli help` and
`dbxcli <cmd> --help` — don't trust memory (e.g. `get`/`put` are
`<source> <target>`, so download is `get <remote> <local>` and upload is
`put <local> <remote>`). The rest of this skill is the stuff `--help` does
*not* tell you.

## ⚠️ Output-parsing gotchas (these caused real wrong conclusions)

1. **`dbxcli ls -R` prints MULTIPLE entries per line** (space-padded columns),
   so `dbxcli ls -R <path> | wc -l` counts *lines*, not files, and **wildly
   undercounts** (e.g. ~4,600 files reported as ~1,160 "lines"). Same trap with
   plain `dbxcli ls` on a folder. **Never count files with line count of the
   default/`-R` output.** Use the **long format** instead — it's one entry per
   line:
   ```bash
   # accurate recursive FILE count (directories have "-" in the revision column)
   dbxcli ls -l -R "/Path" | awk 'NR>1 && $1!="-" {n++} END{print n}'
   ```

2. **`dbxcli du <path>` returns whole-ACCOUNT usage, not the folder's size.**
   Its output (`Used: … / Allocated: …`) is your total Dropbox quota usage and
   is identical for any path. Don't use it to size a folder. To compare a folder
   vs. a local copy, compare **file counts** (recipe above) rather than bytes.

3. **`ls -l` Path column can contain spaces** and the "Last modified" column is
   human text (e.g. "6 minutes ago"), so naive whitespace field-splitting to
   extract paths is unreliable. Counting non-directory rows (`$1!="-"`) is
   robust; extracting exact path strings for a diff is fiddly — prefer
   per-subfolder counts/spot-checks over a full path-level diff.

## Recipe: did a folder finish uploading to the cloud?

```bash
LOCAL="$HOME/Library/CloudStorage/Dropbox/Path/To/Folder"   # local Dropbox copy
REMOTE="/Path/To/Folder"                                    # same path, cloud
echo "local: $(find "$LOCAL" -type f | wc -l | tr -d ' ')"
echo "cloud: $(dbxcli ls -l -R "$REMOTE" | awk 'NR>1 && $1!="-"{n++} END{print n}')"
```
A small transient gap (a handful of files) is normal sync lag; re-run after a
moment. A large persistent gap is a real problem. Spot-check a specific
subfolder with `dbxcli ls -l "$REMOTE/subdir"` to localize it.

## Note on the modern macOS client

On `~/Library/CloudStorage/Dropbox` (Apple File Provider), files added via a
bulk CLI `mv`/`cp` do sync (observed: a ~4,600-file / 600 MB batch uploaded
fully, and the menu bar's "Up to date" was accurate). The real trap is
*misreading* sync state — most often by miscounting `dbxcli ls -R` output (see
gotcha 1). So if a folder looks stuck: **get an accurate server-side count
first** (`ls -l -R` recipe below). Only if that confirms a genuine, persistent
gap should you chase remedies — app restart, granting Dropbox **Full Disk
Access**, or re-adding via Finder (these are commonly-cited Dropbox fixes, not
ones proven necessary here).
