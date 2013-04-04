fs = require "fs"

{spawn, exec} = require "child_process"
{log} = console

module.exports = class Kite

  @help:"""
  Kites are simply web services for Koding.
  You can share your kites over internet.

  kd kite create [name]     Create Kite
  kd kite keygen [name]     Create a key for Kite
  kd kite run               Run the kite in current working directory.
  """

  constructor: ({@config})->
  
  create: (name, key = "")->
    unless name
      return log "You must define a kite name."
    
    if name.match /[^\w]/
      return log "You mustn't use special chars in kite name."

    kiteDir = "#{process.cwd()}/#{name}"
    tmpFile = "/tmp/koding.kd.kite.create.#{Date.now()}"

    log "Creating Kite..."

    # Bash file to run.
    bash = """
    mkdir #{kiteDir}
    cd #{kiteDir}
    touch index.coffee
    mkdir node_modules
    npm install kd-kite
    """

    # Kite index.file
    index = """
    Kite = require 'kd-kite'

    config = 
      name      : '#{name}'
      apiAdress : 'http://localhost:3000'
      key       : '#{key}'

    module.exports = new Kite config,
      ping: (options, callback) ->
        return callback null, "pong from #{name}"
    """
    fs.writeFileSync tmpFile, bash
    log "Installing Kite Modules..."
    exec "bash #{tmpFile}", (err)->
      fs.writeFileSync "#{kiteDir}/index.coffee", index
      log "Your kite created successfully."

  run: ->
    child = spawn "coffee", ["index.coffee"]
    child.stdout.on "data", (data)->
      process.stdout.write data.toString()

  keygen: (name)-> 
    log "Keygen is not available for now. Please use Koding > Account > Kite Keys to have one."