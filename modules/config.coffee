fs = require "fs"
YAML = require "js-yaml"

module.exports = class Config

  {log} = console

  alias:
    ls: "list"

  @help:"""
  Koding configuration settings.

  You can use following commands:

  kd config set
  kd config get
  kd config remove
  kd config list [--json]
  kd config alias ALIAS MODULE
  """

  constructor: (@config)->

  set: (key, value...)->
    unless key and value
      return log "You must define a key and a value to set a config variable."
    @config.set key, value...
    @config.save()

  get: (path)->
    config = @config.getAll()
    try
      value = eval "config.#{path}"
    catch error
      return log "Probably the path #{path} is wrong."

    unless value
      return log "Config #{key} is not defined."
    log value

  remove: (path)->
    config = @config.getAll()
    # not a fancy way.
    try
      eval "delete config.#{path}"
    catch error
      return log "Probably the path #{path} is wrong."
    
    # @config.remove key
    @config.save()

  list:->
    config = @config.getAll()
    log if @options.argv.json then JSON.stringify config, null, 2 else YAML.dump config

  alias: (alias, module)->
    return unless alias or module
    config = @config.getAll()
    config.alias = {} unless config.alias
    config.alias[alias] = module
    @config.save()

  # magic
  __command: (command)-> @get command
