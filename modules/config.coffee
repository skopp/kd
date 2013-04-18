fs = require "fs"

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
  kd config list
  """

  constructor: (@config)->

  set: (key, value...)->
    unless key and value
      return log "You must define a key and a value to set a config variable."
    @config.set key, value...
    @config.save()

  get: (key)->
    value = @config.get key
    unless value
      return log "Config #{key} is not defined."
    log "#{key}=\"#{value}\""

  remove: (key)->
    @config.remove key
    @config.save()

  list:->
    log "#{key}=\"#{item}\"" for key, item of @config.getAll()
