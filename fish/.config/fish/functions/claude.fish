function claude --wraps claude --description 'Claude with default flags'
    if test (count $argv) -gt 0; and not string match -q -- '-*' $argv[1]
        # First arg is a subcommand (e.g. "remote-control"), pass through raw
        command claude $argv
    else
        command claude --dangerously-skip-permissions $argv
    end
end
