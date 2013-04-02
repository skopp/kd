fs = require "fs"

module.exports = class Config

  {log} = console

  @help:"""
  Koding configuration settings.

  kd config set user.name [username]
  kd config set user.email [email]
  """

  constructor: (@configFile)->

  set: (key, value...)->
    unless key and value
      return log "You must define a key and a value to set a config variable."
    @configFile.config[key] = value.join " "
    @configFile.save @configFile.config

  get: (key)->
    value = @configFile.config[key]
    unless value
      return log "Config #{key} is not defined."
    log "#{key}=\"#{}\""

  remove: (key)->
    delete @configFile.config[key]
    @configFile.save @configFile.config