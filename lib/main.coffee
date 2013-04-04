ConfigFile = require "./config"

module.exports = class KodingCLI

  # import log from console.
  {log} = console

  constructor: (@module, @command, @params)->

    # root directory of running command is @root
    @root = process.cwd()

    unless module
      return log """
      Hi, this is the Koding CLI tool.
      You must choose a module. (e.g. kite, app)
      """
    
    # Loading module from the module path.
    try
      @moduleClass = require "#{__dirname}/../modules/#{module}"
    catch error
      log "[Koding] ERROR: Module #{module} not found."
      return

    {help} = @moduleClass

    # If user doesn't define any command, show help. If help is available.
    unless @command
      if help then return log help else return log "It's #{module}s or something. That's all."

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
      @moduleInstance[@command] @params...
    catch error
      # If any error occures, show the error.
      log "[Koding:#{module}] EXCEPTION: #{error.message or error}"

  # Creating new instance from command line tool.
  @run: (coffeeBin, file, module, command, params...) => 
    new @ module, command, params