# AWS CLI completion using aws_completer
# Based on: https://github.com/aws/aws-cli/issues/1079#issuecomment-2225628740
if type -q aws_completer
  function __aws_complete
    set -lx COMP_SHELL fish
    set -lx COMP_LINE (commandline -opc)

    if string match -q -- "-*" (commandline -opt)
      set COMP_LINE $COMP_LINE -
    end

    aws_completer | command sed 's/ $//'
  end

  complete --command aws --no-files --arguments '(__aws_complete)'
end
