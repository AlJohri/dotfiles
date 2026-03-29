#!/usr/bin/env bash
set -euo pipefail

# DEPRECATED: The local Go-based MCP server is being deprecated.
# See: https://github.com/incident-io/incidentio-mcp-golang/commit/b94bc15b990b3bbd035b50d9bfed738f01e02bbe
# Use the remote MCP server instead: https://docs.incident.io/ai/remote-mcp
#
# Sets up the local incident.io MCP server for Claude Code.
# Uses the Go-based MCP server with an API key from 1Password.
# Idempotent: re-running overwrites the existing entry.

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

echo "==> Setting up local incident.io MCP server..."

claude mcp remove incidentio --scope user 2>/dev/null || true
claude mcp add incidentio --scope user -- \
    bash -c 'export INCIDENT_IO_API_KEY=$(OP_ACCOUNT=seltz.1password.com op-fast read "op://Private/Incident.io Admin API Key/credential") && exec go run github.com/incident-io/incidentio-mcp-golang/cmd/mcp-server@latest'

echo "==> Done."
