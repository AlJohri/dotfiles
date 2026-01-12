# uv PATH is handled in config.fish (~/.local/bin)
# This file kept for compatibility if uv installer creates env.fish
if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end
