fs = require "fs"

{spawn, exec} = require "child_process"
{log} = console

module.exports = class Kite

  @help:"""
  Kites are simply web services for Koding.
  You can share your kites over internet.

  You can run following commands:

  kd kite create
  kd kite run
  kd kite test
  kd kite manifest
  kd kite keygen
  """

  constructor: ({@config})->
  
  create: ->

    {argv: {name, key, domain}} = @options
      .usage("Creates a Kite template")
      .demand(["n"])
      .alias("n", "name")
      .alias("k", "key")
      .alias("d", "domain")
      .describe("n", "Name of the Kite")
      .describe("k", "Access key of the Kite")
      .describe("d", "Domain of the Kite, for debug")

    unless name
      return log "You must define a kite name."
    
    if name.match /[^\w]/
      return log "You mustn't use special chars in kite name."

    kiteDir = "#{process.cwd()}/#{name}"
    tmpFile = "/tmp/koding.kd.kite.create.#{Date.now()}"

    # Bash file to run.
    bash = """
    mkdir #{kiteDir}
    cd #{kiteDir}
    touch manifest.js
    touch index.coffee
    mkdir test
    touch test/test.coffee
    mkdir node_modules
    npm install kd-kite kd-rope mocha
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
    log "Installing Kite Modules, please wait..."

    install = spawn "bash", [tmpFile] 
    install.on "close", ->
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
      child.stderr.on "data", (data)->
        process.stdout.write data.toString()
    else
      log "The index.coffee doesn't exist."

  keygen: (name)-> 
    log "Keygen is not available for now. Please use Koding > Account > Kite Keys to have one."

  manifest: ->
    {argv: {key, value}} = @options
      .usage("Creates key-value pairs in manifest.js file.")
      .demand(["k"])
      .alias("k", "key")
      .alias("v", "value")
      .describe("k", "Key of the kite manifest item")
      .describe("v", "Value of the kite manifest item")

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
