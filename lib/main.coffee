fs = require "fs"
ConfigFile = require "./config"
utils = require "./utils"

module.exports = class KodingCLI

  # import log from console.
  {log} = console

  KD_DIR = "#{process.env.HOME}/.kd"
  MODULE_ROOT = "#{__dirname}/../modules"
  USER_MODULE_ROOT = "#{KD_DIR}/modules"

  constructor: (@module, @command, @params)->

    # root directory of running command is @root
    @root = process.cwd()

    publicKeyPath = "#{KD_DIR}/koding.key.pub"
    privateKeyPath = "#{KD_DIR}/koding.key"
    try
      publicKey = fs.readFileSync(publicKeyPath).toString()
    catch error
      try
        unless fs.existsSync KD_DIR then fs.mkdirSync KD_DIR
      publicKey = utils.keygen 64
      fs.writeFileSync publicKeyPath, publicKey

    try
      privateKey = fs.readFileSync(privateKeyPath).toString()
    catch error
      try
        unless fs.existsSync KD_DIR then fs.mkdirSync KD_DIR
      privateKey = utils.keygen 64
      fs.writeFileSync privateKeyPath, privateKey

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

    @configFile.config.publicKey = publicKey
    @configFile.config.privateKey = privateKey
    
    # Loading module from the module path.
    try
      @moduleClass = require "#{MODULE_ROOT}/#{module}"
    catch error
      try
        @moduleClass = require "#{USER_MODULE_ROOT}/#{module}"
      catch error
        try
          @moduleClass = require "#{process.cwd()}/Kodingfile.coffee"
          _originalCommand = command
          command = @command = module
          module = @module = ":Kodingfile"
        catch error
          log "[Koding] ERROR: Module #{module} not found."
          return

    {help, silent} = @moduleClass.prototype

    unless @command
      if help
        log "#{help}\n" 

      unless help is no
        log "You can use following commands for #{module}:\n"

      commands = (command for command, method of @moduleClass.prototype when typeof method is "function" and not command.match /__/).sort()
      log "kd #{module} #{command}" for command in commands
      return

    if @command is "help" then return log help

    # Trying to create new instance.
    try
      @moduleInstance = new @moduleClass @configFile
    catch error
      unless silent
        log error
        log "[Koding:#{module}] ERROR: Module instance couldn't be created."
      return

    # Replace command with the alias
    if @moduleInstance.alias?[@command]
      @command = @moduleInstance.alias[@command]

    # Trying to *find* new instances method as command
    unless @moduleInstance[@command]
      unless @moduleInstance.__command
        unless silent
          log "[Koding:#{module}] ERROR: Command #{command} not found."
        return
      else
        nocommand = true

    # Trying to run the command.
    try
      @moduleInstance.options = require "optimist"
      unless nocommand
        if _originalCommand and module is ":Kodingfile"
          @params.reverse()
          @params.push _originalCommand
          @params.reverse()
        @moduleInstance[@command] @params...
      else
        @moduleInstance.__command @command, @params
    catch error
      # If any error occures, show the error.
      unless silent
        log "[Koding:#{module}] EXCEPTION: #{error.message or error}"

  # Creating new instance from command line tool.
  @run: (coffeeBin, file, module, command, params...) =>
    new @ module, command, params
