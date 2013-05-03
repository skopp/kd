fs = require "fs"

{log} = console

module.exports = class Completion

  silent: yes

  CACHE_ROOT = "#{process.env.HOME}/.kd/"
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
        '*: :->_rest' \\
      && return 0

      # State Change
      case $state in
        _module)
          _arguments '1:_module:(`kd completion modules`)'
        ;;
        _command)
          _arguments '2:_command:(`kd completion commands --module=${words[2]}`)'
        ;;
        _rest)
          _files
        ;;
      esac

    }
    compdef _kd_completion kd
  elif type complete &>/dev/null; then
    _kd_completion() {

      if [ "$COMP_CWORD" -eq 2 ]; then
        COMPREPLY=( $(compgen -f -- ${COMP_WORDS[COMP_CWORD]}) )
      else
        COMPREPLY=(`kd completion complete "$COMP_CWORD" "$COMP_LINE"`)
      fi

    }
    complete -F _kd_completion kd
  fi
  """

  modules = ->
    cacheFile = "/tmp/koding.kd.completion.modules.json"
    try
      return require cacheFile
    catch error
      available = fs.readdirSync MODULE_ROOT
      try
        userAvailable = fs.readdirSync USER_MODULE_ROOT
      catch error
        userAvailable = []

      moduleList = available.concat(userAvailable).sort().map((module)-> module.replace /.coffee$/, '')
      fs.writeFileSync cacheFile, JSON.stringify moduleList, null, 2
      return moduleList

  commands = (module)->
    cacheFile = "/tmp/koding.kd.completion.commands.#{module}.json"
    try
      return require cacheFile
    catch error
      try
        moduleClass = require "#{MODULE_ROOT}/#{module}"
      catch error
        try
          moduleClass = require "#{USER_MODULE_ROOT}/#{module}"
        catch error
          return ""
    try
      commandList = (command for command, method of moduleClass.prototype when typeof method is "function" and not command.match /__/).sort()
      try
        commandList = commandList.concat Object.keys moduleClass.prototype.alias
      fs.writeFileSync cacheFile, JSON.stringify commandList, null, 2
      return commandList

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