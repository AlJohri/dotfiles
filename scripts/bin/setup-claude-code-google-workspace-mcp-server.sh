#!/usr/bin/env bash
set -euo pipefail

# Sets up the google_workspace_mcp server for Claude Code (multi-account
# Gmail/Calendar/Drive/Docs/Sheets, write-capable). Registered at user scope.
# Idempotent: re-running overwrites the existing entry.
#
# Reuses the gog (gogcli) OAuth client via GOOGLE_CLIENT_SECRET_PATH, so no
# client id/secret is duplicated into ~/.claude.json. The client secret is a
# bring-your-own Desktop OAuth client (provisioned by the gog setup runbook).
# If the local file is missing, it is materialized from 1Password (personal
# account), so a fresh machine bootstraps without hand-copying the file.
#
# Per-account OAuth tokens are also stashed in 1Password and materialized here.
# The OAuth app is published (In production), so refresh tokens are long-lived —
# a fresh machine gets zero-consent access as long as the stashed token is still
# valid; if it's stale, the first tool call just re-triggers browser consent.

CLIENT_SECRET="$HOME/.config/gogcli/client_secret_gog.json"
CREDS_DIR="$HOME/.google_workspace_mcp/credentials"
# 1Password references (personal account). op-fast + op:// reference, matching
# the incident.io setup script's pattern.
OP_ACCT="my.1password.com"
OP_REF="op://Private/gog OAuth Client Secret/credential"
# Per-account OAuth tokens live in ONE field: a JSON object keyed by the real
# account email -> that account's token JSON. Emails are data (JSON keys), never
# part of an op:// reference, so nothing needs sanitizing and the key set IS the
# account list. Add an account by adding a key to this field.
OP_TOKENS_REF="op://Private/google_workspace_mcp/tokens"

missing=()
for cmd in claude uvx jq; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
    echo "ERROR: missing required commands: ${missing[*]}" >&2
    exit 1
fi

# Materialize the OAuth client secret from 1Password if the local file is
# absent (gog needs this exact file too). Skip rather than register a broken
# entry when neither the file nor 1Password is available — mirrors the
# incident.io script's "no 1Password → skip" path.
if [ ! -f "$CLIENT_SECRET" ]; then
    if ! command -v op-fast &>/dev/null \
       || ! OP_ACCOUNT="$OP_ACCT" op account list --format=json 2>/dev/null | grep -q '"url"'; then
        echo "WARNING: $CLIENT_SECRET missing and 1Password ($OP_ACCT) unavailable, skipping." >&2
        echo "         Sign in to the 1Password CLI (or provision the gog Desktop" >&2
        echo "         OAuth client per the gog runbook), then re-run this script." >&2
        exit 0
    fi
    echo "==> Client secret not on disk; materializing from 1Password ($OP_ACCT)..."
    mkdir -p "$(dirname "$CLIENT_SECRET")"
    secret_json="$(OP_ACCOUNT="$OP_ACCT" op-fast read "$OP_REF" 2>/dev/null || true)"
    if [ -z "$secret_json" ]; then
        echo "WARNING: could not read \"$OP_REF\" from 1Password, skipping." >&2
        exit 0
    fi
    ( umask 077; printf '%s' "$secret_json" > "$CLIENT_SECRET" )
    echo "    Wrote $CLIENT_SECRET (chmod 600)."
fi

# Materialize per-account OAuth tokens from 1Password if not already on disk.
# The `tokens` field is a JSON object { "<email>": <token json>, ... }; iterate
# its keys. Non-fatal: a missing/unreadable token just means that account needs a
# one-time interactive consent later (the server auto-triggers it on first call).
if command -v op-fast &>/dev/null \
   && OP_ACCOUNT="$OP_ACCT" op account list --format=json 2>/dev/null | grep -q '"url"'; then
    tokens_json="$(OP_ACCOUNT="$OP_ACCT" op-fast read "$OP_TOKENS_REF" 2>/dev/null || true)"
    if [ -n "$tokens_json" ] && printf '%s' "$tokens_json" | jq -e . >/dev/null 2>&1; then
        while IFS= read -r email; do
            token_file="$CREDS_DIR/$email.json"
            [ -f "$token_file" ] && continue
            mkdir -p "$CREDS_DIR"
            ( umask 077; printf '%s' "$tokens_json" | jq --arg e "$email" '.[$e]' > "$token_file" )
            echo "==> Materialized token for $email from 1Password."
        done < <(printf '%s' "$tokens_json" | jq -r 'keys[]')
    fi
fi

echo "==> Setting up google_workspace_mcp server..."

claude mcp remove google-workspace --scope user 2>/dev/null || true
claude mcp add google-workspace --scope user \
    -e "GOOGLE_CLIENT_SECRET_PATH=$CLIENT_SECRET" \
    -e "OAUTHLIB_INSECURE_TRANSPORT=1" \
    -- uvx workspace-mcp --single-user \
       --tools gmail calendar drive docs sheets

echo "==> Done. Accounts with a stashed 1Password token are ready to use."
echo "    Any account without one is authenticated on first tool call (browser"
echo "    consent); tokens land in ~/.google_workspace_mcp/credentials/."
