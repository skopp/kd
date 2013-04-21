fs = require "fs"
ConfigFile = require "./config"

module.exports = class KodingCLI

  # import log from console.
  {log} = console

  MODULE_ROOT = "#{__dirname}/../modules"
  USER_MODULE_ROOT = "#{process.env.HOME}/.kd/modules"

  constructor: (@module, @command, @params)->

    # root directory of running command is @root
    @root = process.cwd()

    unless module

      available = fs.readdirSync MODULE_ROOT
      try
        userAvailable = fs.readdirSync USER_MODULE_ROOT
      catch error
        userAvailable = []

      available = available.concat(userAvailable).sort()

      log """
      Hi, this is the Koding CLI tool.
      You must choose a module.

      """
      log "You can run following modules:\n"
      log "kd #{module.replace /.coffee$/, ''} [command]" for module in available
      return

    @configFile = new ConfigFile

    # Replace module with the alias
    if @configFile.config.alias?[module]
      module = @configFile.config.alias[module]
    
    # Loading module from the module path.
    try
      @moduleClass = require "#{MODULE_ROOT}/#{module}"
    catch error
      try
        @moduleClass = require "#{USER_MODULE_ROOT}/#{module}"
      catch error
        log "[Koding] ERROR: Module #{module} not found."
        return

    {help} = @moduleClass.prototype

    # If user doesn't define any command, show help. If help is available.
    showHelp = ->

    unless @command
      if help
        log "#{help}\n" 

      log "You can use following commands for #{module}:\n"

      commands = (command for command, method of @moduleClass.prototype when typeof method is "function" and not command.match /__/).sort()
      log "kd #{module} #{command}" for command in commands
      return

    if @command is "help" then return log help

    # Trying to create new instance.
    try
      @moduleInstance = new @moduleClass @configFile
    catch error
      log error
      log "[Koding:#{module}] ERROR: Module instance couldn't be created."
      return

    # Replace command with the alias
    if @moduleInstance.alias?[@command]
      @command = @moduleInstance.alias[@command]

    # Trying to *find* new instances method as command
    unless @moduleInstance[@command]
      unless @moduleInstance.__command
        log "[Koding:#{module}] ERROR: Command #{command} not found."
        return
      else
        nocommand = true

    # Trying to run the command.
    try
      @moduleInstance.options = require "optimist"
      unless nocommand
        @moduleInstance[@command] @params...
      else
        @moduleInstance.__command @command, @params
    catch error
      # If any error occures, show the error.
      log "[Koding:#{module}] EXCEPTION: #{error.message or error}"

  # Creating new instance from command line tool.
  @run: (coffeeBin, file, module, command, params...) => 
    new @ module, command, params
