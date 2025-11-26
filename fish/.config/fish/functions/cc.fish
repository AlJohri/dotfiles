function cc
    mkdir -p /tmp/claude-code/ && env --chdir /tmp/claude-code/ claude --dangerously-skip-permissions $argv
end
