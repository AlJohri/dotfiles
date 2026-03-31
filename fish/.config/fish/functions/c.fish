# Overrides: https://github.com/omacom-io/omarchy-fish/blob/master/functions/c.fish
# See also: https://github.com/omacom-io/omarchy-fish/blob/master/functions/cx.fish
function c --description 'Launch Claude Code'
  claude --dangerously-skip-permissions $argv
end
