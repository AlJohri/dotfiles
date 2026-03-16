#!/usr/bin/env bash
set -euo pipefail

# Installs MCP servers for Claude Code using `claude mcp add`.
# Idempotent: re-running overwrites existing entries with the same name.

echo "==> Installing Claude Code MCP servers..."

claude mcp remove incidentio --scope user 2>/dev/null || true
claude mcp add incidentio --scope user -- \
    bash -c 'export INCIDENT_IO_API_KEY=$(op-fast item get "Incident.io Admin API Key" --account seltz.1password.com --reveal --fields credential) && exec go run github.com/incident-io/incidentio-mcp-golang/cmd/mcp-server@latest'

echo "==> Done."
