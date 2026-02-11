# Lazily set MISE_GITHUB_TOKEN on first mise command
# https://mise.jdx.dev/troubleshooting.html#_403-forbidden-when-installing-a-tool
# https://github.com/jdx/mise/discussions/7193
function __mise_github_token_hook --on-event fish_preexec
    if string match -qr '^mise\b' -- $argv
        set -gx MISE_GITHUB_TOKEN (gh auth token 2>/dev/null)
        functions -e __mise_github_token_hook
    end
end
