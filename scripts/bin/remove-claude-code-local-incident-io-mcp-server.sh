#!/usr/bin/env bash
set -euo pipefail

# DEPRECATED: The local Go-based MCP server is being deprecated.
# See: https://github.com/incident-io/incidentio-mcp-golang/commit/b94bc15b990b3bbd035b50d9bfed738f01e02bbe
# Use the remote MCP server instead: https://docs.incident.io/ai/remote-mcp
#
# Removes the local incident.io MCP server from Claude Code.

echo "==> Removing local incident.io MCP server..."

claude mcp remove incidentio --scope user 2>/dev/null || true

echo "==> Done."
