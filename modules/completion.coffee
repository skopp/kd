fs = require "fs"

{log} = console

module.exports = class Completion

  MODULE_ROOT = __dirname
  USER_MODULE_ROOT = "#{process.env.HOME}/.kd/modules"

  shell: -> log """
  # KD Autocompletion Utility
  # Uses kd --modules and kd [module] --commands
  # to make completion.

  if type compdef &>/dev/null; then
    _kd_completion() {

      # Defining argument stats
      _arguments \\
        '1: :->_module' \\
        '2: :->_command' \\
      && return 0

      # State Change
      case $state in
        _module)
          _arguments '1:_service:(`kd completion modules`)'
        ;;
        _command)
          _arguments '2:_module:(`kd completion commands --module=${words[2]}`)'
        ;;
      esac

    }
    compdef _kd_completion kd
  elif type complete &>/dev/null; then
    _kd_completion() {

      local si="$IFS"
      COMPREPLY=(`kd completion complete "$COMP_CWORD" "$COMP_LINE"`)
      IFS="$si"

    }
    complete -F _kd_completion kd
  fi
  """

  modules = ->
    available = fs.readdirSync MODULE_ROOT
    try
      userAvailable = fs.readdirSync USER_MODULE_ROOT
    catch error
      userAvailable = []

    available.concat(userAvailable).sort().map((module)-> module.replace /.coffee$/, '')

  commands = (module)->
    try
      moduleClass = require "#{MODULE_ROOT}/#{module}"
    catch error
      try
        moduleClass = require "#{USER_MODULE_ROOT}/#{module}"
      catch error
        return ""
    try
      (command for command, method of moduleClass.prototype when typeof method is "function" and not command.match /__/).sort()

  modules: -> log modules().join "\n"
  commands: -> log commands(@options.argv.module).join "\n"

  # This is for bash. ZSH is more easy than it. :)
  complete: (cword, line) ->
    cword = parseInt cword
    line = line.split /\s+/
    switch cword
      when 1
        word = line.slice -1
        _modules = modules().filter (module)-> 
          module.match new RegExp("^#{word}")
        log _modules.join "\n"
      when 2
        module = line.slice -2, -1
        word = line.slice -1
        _commands = commands(module).filter (command)-> 
          command.match new RegExp("^#{word}")
        log _commands.join "\n"

  bash: ->
    # Because of OS X's EPIPE error, we need to give
    # executable permission and run.
    log """
    mkdir -p ~/.kd
    kd completion shell > ~/.kd/completion.sh
    chmod +x ~/.kd/completion.sh
    echo "source ~/.kd/completion.sh" >> ~/.bashrc
    """

  zsh: ->
    log 'echo "source <(kd completion shell)" >> ~/.zshrc'