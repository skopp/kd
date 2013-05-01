YAML = require "js-yaml"
fs = require "fs"

module.exports = class ConfigFile

  disabled: ["publicKey", "privateKey"]

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
    @disabled.forEach (item)=> @remove item
    fs.writeFileSync @configFile, YAML.dump @config

  load:-> 
    @config = YAML.load fs.readFileSync(@configFile).toString()