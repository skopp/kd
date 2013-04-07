fs = require "fs"

{spawn, exec} = require "child_process"
{log} = console

module.exports = class Kite

  @help:"""
  Kites are simply web services for Koding.
  You can share your kites over internet.

  kd kite create --name [name] --key [key]    Create Kite
  kd kite manifest key [value]                Set/Get Manifest Variable
  kd kite run                                 Run the kite in current working directory.
  """

  constructor: ({@config})->
  
  create: ()->

    {name, key, domain} = @options

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
    touch manifest.js
    touch index.coffee
    mkdir test
    touch test/test.coffee
    mkdir node_modules
    npm install kd-kite mocha
    """

    # Kite index.file
    index = """
    ###
    #{name} Kite for Koding
    Author: #{@config['user.name']} <#{@config['user.email'] or 'you@example.com'}>
    ###
    Kite = require 'kd-kite'
    manifest = require './manifest'

    module.exports = new Kite manifest,
      pingKite: (options, callback) ->
        return callback null, "pong from #{name}"
    """

    manifest = 
      name      : name or 'Untitled',
      apiAdress : domain or 'https://koding.com',
      key       : key or ''

    fs.writeFileSync tmpFile, bash
    log "Installing Kite Modules..."
    exec "bash #{tmpFile}", (err)->
      fs.writeFileSync "#{kiteDir}/index.coffee", index
      manifestData = JSON.stringify manifest, null, 2
      fs.writeFileSync "#{kiteDir}/manifest.js", "module.exports = #{manifestData};"
      log "Your kite created successfully."

  run: ->
    kiteFile = "#{process.cwd()}/index.coffee"
    exists = fs.existsSync kiteFile
    
    if exists
      child = spawn "coffee", [kiteFile]
      child.stdout.on "data", (data)->
        process.stdout.write data.toString()
    else
      log "The index.coffee doesn't exist."

  keygen: (name)-> 
    log "Keygen is not available for now. Please use Koding > Account > Kite Keys to have one."

  manifest: (key, value)->
    manifestFile = "#{process.cwd()}/manifest.js"
    manifest = require manifestFile
    unless value
      log manifest[key]
    else
      manifest[key] = value
      manifestData = JSON.stringify manifest, null, 2
      fs.writeFileSync manifestFile, "module.exports = #{manifestData};"


  test: ->
    kiteTestFile = "#{process.cwd()}/test/test.coffee"
    exists = fs.existsSync kiteTestFile

    if exists
      exec "coffee -c #{kiteTestFile}", ->
        child = spawn "#{process.cwd()}/node_modules/mocha/bin/mocha", [kiteTestFile]
        child.stdout.on "data", (data)->
          process.stdout.write data.toString()
    else
      log "The test file doesn't exist."