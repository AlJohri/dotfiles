if status is-interactive; and set -q GHOSTTY_RESOURCES_DIR
    set -g __ghostty_log ~/.local/state/ghostty-tabs.log

    # Log shell start (new tab/pane)
    echo "START "(date +%s)" $fish_pid "(pwd) >> $__ghostty_log

    # Log directory changes
    function __ghostty_track_cd --on-variable PWD
        echo "CD "(date +%s)" $fish_pid $PWD" >> $__ghostty_log
    end

    # Log shell exit (tab/pane closed, or window destroyed)
    function __ghostty_track_exit --on-event fish_exit
        echo "EXIT "(date +%s)" $fish_pid" >> $__ghostty_log
    end
end
