fs = require "fs"

module.exports = class ConfigFile
  constructor: ->
    @configFile = "#{process.env.HOME}/.kdconfig"
    try
      @config = @load @configFile
    catch error
      @config = {}
      @save()

  get: (key)-> @config[key]
  set: (key, value...)-> @config[key] = value.join " "
  remove: (key)-> delete @config[key]

  getAll: -> @config

  save:->
    fs.writeFileSync @configFile, JSON.stringify @config, null, 2

  load:-> 
    @config = JSON.parse fs.readFileSync @configFile