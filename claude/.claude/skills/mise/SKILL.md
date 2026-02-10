---
name: mise
description: Figure out if a tool can be installed via mise (across all backends) and install it.
user_invocable: true
---

# Mise Tool Installer

Given `/mise <tool>`, figure out if the tool can be installed via [mise](https://mise.jdx.dev/) and install it.

Mise supports many backends beyond its built-in registry, so a tool not appearing in `mise search` does NOT mean it can't be installed. You must explore multiple backends.

## Step 1: Check the mise registry first

Run `mise search <tool>` to see if there's a direct match or close match in the registry.

If a match is found, skip to Step 3 using that short name (e.g. `ripgrep`, `neovim`).

## Step 2: Search across backends

If `mise search` didn't find a match, try to find the tool across mise's backends. Research in this order:

1. **GitHub Releases** — Search GitHub for the project. If you find a repo that publishes binary releases, the tool can likely be installed via:
   - `github:<owner>/<repo>` (uses [aqua](https://mise.jdx.dev/dev-tools/backends/ubi.html) or [ubi](https://mise.jdx.dev/dev-tools/backends/ubi.html) under the hood)
   - `ubi:<owner>/<repo>` (explicitly use the [ubi backend](https://mise.jdx.dev/dev-tools/backends/ubi.html))

2. **PyPI** — If the tool is a Python package, it can be installed via:
   - `pipx:<package>` ([pipx backend](https://mise.jdx.dev/dev-tools/backends/pipx.html))

3. **npm** — If the tool is a Node.js package, it can be installed via:
   - `npm:<package>` ([npm backend](https://mise.jdx.dev/dev-tools/backends/npm.html))

4. **Cargo** — If the tool is a Rust crate, it can be installed via:
   - `cargo:<crate>` ([cargo backend](https://mise.jdx.dev/dev-tools/backends/cargo.html))

5. **Go** — If the tool is a Go module, it can be installed via:
   - `go:<module>` ([go backend](https://mise.jdx.dev/dev-tools/backends/go.html))

6. **Conda** — If the tool is a conda/conda-forge package:
   - Check https://anaconda.org for the package
   - `conda:<channel>/<package>` ([conda backend](https://mise.jdx.dev/dev-tools/backends/conda.html))

Use web search to determine which backend is most appropriate for the tool.

## Step 3: Install the tool

Once you've identified the correct mise specifier, install it:

```bash
mise install <specifier>@latest
```

If installation fails, try alternative backends from Step 2 before giving up.

## Step 4: Verify the installation

After installation, verify it works by running one of:

```bash
mise exec <specifier>@latest -- <tool> --version
mise exec <specifier>@latest -- <tool> --help
```

Try `--version` first, then `--help` if that fails. Some tools use `-V`, `-v`, or `version` as subcommands — try those too if needed. The goal is to confirm the binary is functional.

## Step 5: Report

Report to the user:
- The mise specifier that works (e.g. `github:owner/repo`, `npm:package`, or just the short name)
- The installed version
- The command to add it globally: `mise use --global <specifier>@latest`
