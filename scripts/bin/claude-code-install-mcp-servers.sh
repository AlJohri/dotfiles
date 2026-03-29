#!/usr/bin/env bash
set -euo pipefail

# Installs MCP servers for Claude Code using `claude mcp add`.
# Idempotent: re-running overwrites existing entries with the same name.

missing=()
for cmd in claude go op op-fast; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
    echo "ERROR: missing required commands: ${missing[*]}" >&2
    exit 1
fi

# Verify 1Password CLI has a configured account
if ! op account list --format=json 2>/dev/null | grep -q '"url"'; then
    echo "WARNING: no 1Password accounts configured, skipping MCP server installation." >&2
    echo "         To install later, sign in to 1Password CLI and re-run this script." >&2
    echo "         See: https://developer.1password.com/docs/cli/app-integration/" >&2
    exit 0
fi

echo "==> Priming op-fast cache..."
OP_ACCOUNT=seltz.1password.com op-fast read "op://Private/Incident.io Admin API Key/credential" >/dev/null
echo "    op-fast cache primed."

echo "==> Installing Claude Code MCP servers..."

claude mcp remove incidentio --scope user 2>/dev/null || true
claude mcp add incidentio --scope user -- \
    bash -c 'export INCIDENT_IO_API_KEY=$(OP_ACCOUNT=seltz.1password.com op-fast read "op://Private/Incident.io Admin API Key/credential") && exec go run github.com/incident-io/incidentio-mcp-golang/cmd/mcp-server@latest'

echo "==> Done."
