fs = require "fs"
YAML = require "js-yaml"
Progress = require "progress"

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
    mkdir #{kiteDir}.kite
    cd #{kiteDir}.kite
    touch .manifest.yml
    touch index.coffee
    mkdir resources
    mkdir test
    touch test/test.coffee
    mkdir node_modules
    npm install kd-kite kd-rope js-yaml mocha
    """

    # Kite index.file
    index = """
    ###
    #
    #  #{name} Kite for Koding
    #  Author: #{@config['user.name']} <#{@config['user.email'] or 'you@example.com'}>
    #
    #  This is an example kite with two methods:
    #
    #    - helloWorld
    #    - fooBar
    #
    ###
    require 'js-yaml'
    Kite = require 'kd-kite'
    rope = require 'kd-rope'
    manifest = require './.manifest.yml'

    kite = new Kite manifest,

      ###
      # This is a dummy method of the kite.
      ###
      helloWorld: ({name}, callback) ->
        
        # anotherKite = rope kite, 'anotherKite'
        
        # anotherKite.pingKite {param: true}, (err, result)->
        #   callback null, result

        return callback null, "Hello, \#{name}! This is #{name}"

      ###
      # You can call another kites.
      ###
      fooBar: ({name}, callback) ->
        
        # Let's connect to another kite ..
        awosemekite = rope kite, 'awosemekite'

        # .. and run a method of it.
        awosemekite.helloWorld name: "#{@config['user.name']}", (err, result)->
          callback null, result
    
    module.exports = kite
    """

    manifest = 
      name      : name or 'Untitled',
      apiAdress : domain or 'https://koding.com',
      key       : key or ''

    fs.writeFileSync tmpFile, bash
    log "Creating a new Kite, please wait..."

    install = spawn "bash", [tmpFile]

    progress = new Progress 'Installing dependencies: [:bar] :percent :etas', 
      total: 220
      incomplete: " "
      width: 20

    ticker = ->
      progress.tick()

    install.stdout.on "data", (data)-> do ticker # process.stdout.write(""+i++); process.stdout.write data.toString()
    install.stderr.on "data", (data)-> do ticker # process.stdout.write(""+i++); process.stdout.write data.toString()

    install.on "close", ->
      fs.writeFileSync "#{kiteDir}.kite/index.coffee", index
      manifestData = YAML.dump manifest
      fs.writeFileSync "#{kiteDir}.kite/.manifest.yml", manifestData
      progress.tick(progress.total - progress.curr) # complete the blank.
      log "\nYour kite created successfully."
      log """
      Now enter into kite directory and run the kite with the following commands:

      cd #{kiteDir}.kite
      kd kite run
      """
      process.exit()

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
      .usage("Creates key-value pairs in .manifest.yml file.")
      .demand(["k"])
      .alias("k", "key")
      .alias("v", "value")
      .describe("k", "Key of the kite manifest item")
      .describe("v", "Value of the kite manifest item")

    manifestFile = "#{process.cwd()}/.manifest.yml"
    manifest = require manifestFile
    unless value
      log manifest[key]
    else
      manifest[key] = value
      manifestData = YAML.dump manifest
      fs.writeFileSync manifestFile, manifestData


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
