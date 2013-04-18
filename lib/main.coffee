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
      You must choose a module. (e.g. kite, app)

      """
      log "You can run following modules:\n"
      log "kd #{module.replace /.coffee$/, ''} [command]" for module in available
      return
    
    # Loading module from the module path.
    try
      @moduleClass = require "#{MODULE_ROOT}/#{module}"
    catch error
      try
        @moduleClass = require "#{USER_MODULE_ROOT}/#{module}"
      catch error
        log "[Koding] ERROR: Module #{module} not found."
        return

    {help} = @moduleClass

    # If user doesn't define any command, show help. If help is available.
    unless @command
      if help then return log help else return log "[Koding:#{module}] You are alone. There's no help."

    if @command is "help" then return log help

    # Trying to create new instance.
    try
      @moduleInstance = new @moduleClass new ConfigFile
    catch error
      log error
      log "[Koding:#{module}] ERROR: Module instance couldn't be created."
      return

    # Replace command with the alias
    if @moduleInstance.alias?[@command]
      @command = @moduleInstance.alias[@command]

    # Trying to *find* new instances method as command
    unless @moduleInstance[@command]
      log "[Koding:#{module}] ERROR: Command #{command} not found."
      return

    # Trying to run the command.
    try
      @moduleInstance.options = require "optimist"
      @moduleInstance[@command] @params...
    catch error
      # If any error occures, show the error.
      log "[Koding:#{module}] EXCEPTION: #{error.message or error}"

  # Creating new instance from command line tool.
  @run: (coffeeBin, file, module, command, params...) => 
    new @ module, command, params
