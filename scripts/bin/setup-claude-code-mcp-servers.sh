#!/usr/bin/env bash
set -euo pipefail

# Sets up all MCP servers for Claude Code.
# Delegates to individual setup scripts for each server.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/setup-claude-code-local-incident-io-mcp-server.sh"
