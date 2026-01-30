# Claude Code

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) configuration managed via GNU Stow.

## Tracked Files

| Path | Purpose |
|------|---------|
| `~/.claude/settings.json` | Global settings (shared across machines) |
| `~/.claude/commands/` | Custom slash commands |
| `~/.claude/skills/` | Custom skills |

## Not Tracked

| Path | Reason |
|------|--------|
| `~/.claude/settings.local.json` | Machine-specific permissions (by design) |
| `~/.claude/.credentials.json` | Auth secrets |
| `~/.claude/history.jsonl` | Session history |
| `~/.claude/{cache,debug,plans,todos,...}/` | Runtime/ephemeral data |
| `~/.claude/skills/omarchy` | Symlink managed by [Omarchy](https://omarchy.org/), not stow |

The `omarchy` skill is an absolute symlink created by omarchy itself pointing to
`~/.local/share/omarchy/default/omarchy-skill`. Stow automatically avoids folding
the `skills/` directory into a single symlink because it already contains the
non-stow-managed `omarchy` entry. This means stow creates individual per-entry
symlinks instead:

```
~/.claude/skills/
├── omarchy    -> /home/aljohri/.local/share/omarchy/default/omarchy-skill  # managed by omarchy
└── test-skill -> ../../dotfiles/claude/.claude/skills/test-skill           # managed by stow
```

## XDG Base Directory

Claude Code currently stores both config and data in `~/.claude/` rather than
following the XDG Base Directory Specification (`~/.config/` / `~/.local/share/`).
Tracking resolution of this upstream:
https://github.com/anthropics/claude-code/issues/1455
