function gwt
    if test (count $argv) -eq 0
        command gwt
    else
        set dir (command gwt $argv)
        and builtin cd $dir
    end
end
