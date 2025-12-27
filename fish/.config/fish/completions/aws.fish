# AWS CLI completion using aws_completer
# Based on: https://github.com/aws/aws-cli/issues/1079#issuecomment-2225628740
if type -q aws_completer
  function __aws_complete
    set -lx COMP_SHELL fish
    # Use -cp to preserve trailing space (tells completer we want next argument)
    set -lx COMP_LINE (commandline -cp)

    aws_completer | command sed 's/ $//'
  end

  complete --command aws --no-files --arguments '(__aws_complete)'
end
