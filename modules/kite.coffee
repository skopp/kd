fs = require "fs"
url = require "url"
YAML = require "js-yaml"
Progress = require "progress"

{spawn, exec} = require "child_process"
{log} = console

module.exports = class Kite

  alias:
    "new": "create"
    "i": "install"

  help:"""
  Kites are simply web services for Koding.
  You can share your kites over internet.
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
    
    if name.match /[^\w]/
      return log "You mustn't use special chars in kite name."

    kiteDir = "#{process.cwd()}/#{name}.kite"
    tmpFile = "/tmp/koding.kd.kite.create.#{Date.now()}"

    # Bash file to run.
    # TODO: write full paths
    bash = """
    mkdir -p #{kiteDir}
    cd #{kiteDir}
    touch #{kiteDir}/.manifest.yml
    touch #{kiteDir}/index.coffee
    mkdir -p #{kiteDir}/resources
    mkdir -p #{kiteDir}/test
    touch #{kiteDir}/test/test.coffee
    mkdir -p #{kiteDir}/node_modules
    npm install kd-kite kd-rope js-yaml mocha
    """

    # Kite index.file
    index = """
    ###
    #
    #  #{name} Kite for Koding
    #  Author: #{@config['user.name'] or 'yourusername'} <#{@config['user.email'] or 'you@example.com'}>
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
      fooBar: (options, callback) ->
        
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
      fs.writeFileSync "#{kiteDir}/index.coffee", index
      manifestData = YAML.dump manifest
      fs.writeFileSync "#{kiteDir}/.manifest.yml", manifestData
      progress.tick(progress.total - progress.curr) # complete the blank.
      log "\nYour kite created successfully."
      log """
      Now enter into kite directory and run the kite with the following commands:

      cd #{kiteDir}
      kd kite run
      """
      process.exit()

  install: (repos...)->
    cwd = process.cwd()
    tmpFile = "/tmp/koding.kd.kite.install.#{Math.random()}"
    bash = []
    try
      deps = if repos.length then repos else require("#{cwd}/.manifest.yml").dependencies
    catch error
      throw "It doesn't look like a Kite."

    for dep, i in deps
      _url = url.parse dep
      unless _url.hostname
        __url = url.format
          protocol: 'https'
          host: 'github.com'
          pathname: _url.pathname
        deps[i] = __url

    for dep in deps
      _url = url.parse dep
      bash.push """
      echo [Koding:kite] Found a dependency: #{_url.pathname}
      echo [Koding:kite] Found the route: #{dep}
      echo [Koding:kite]
      echo [Koding:kite] Creating the kite #{_url.pathname}...
      mkdir -p #{cwd}/kites/./#{_url.pathname}
      echo [Koding:kite]
      echo [Koding:kite] Requesting #{dep} to clone.
      git clone --recursive -q #{dep} #{cwd}/kites/./#{_url.pathname}
      echo [Koding:kite]
      echo [Koding:kite] Trying to install npm dependencies if exist.
      cd #{cwd}/kites/./#{_url.pathname} && npm i --loglevel=silent
      echo [Koding:kite] Trying to install sub-dependencies of the kite.
      cd #{cwd}/kites/./#{_url.pathname} && kd kite i
      echo [Koding:kite]
      """
    bash.push "echo [Koding:kite] fin."
    bash = bash.join "\n"

    if deps.length > 0
      fs.writeFileSync tmpFile, bash
      install = spawn "bash", [tmpFile]
      install.stdout.on "data", (data)-> process.stdout.write data
      install.stderr.on "data", (data)-> process.stdout.write "[Koding:kite] ERROR "; process.stdout.write data
    else
      throw "You need to have something to install."

  run: ->
    cwd = process.cwd()
    kiteFile = "#{cwd}/index.coffee"
    exists = fs.existsSync kiteFile
    
    if exists
      dependedFile = "/tmp/koding.kd.kite.depended.#{Math.random()}"
      log "Starting depended kites if exists."
      depended = """
      for manifest in $(find #{cwd}/kites -name ".manifest.yml")
      do
        echo Running `dirname $manifest`...
        coffee `dirname $manifest`/index.coffee &
      done
      """
      fs.writeFileSync dependedFile, depended
      dependencies = spawn "sh", [dependedFile]
      dependencies.stdout.on "data", (data)->
        process.stdout.write data
      dependencies.stdout.on "end", ->
        child = spawn "coffee", [kiteFile]
        child.stdout.on "data", (data)->
          process.stdout.write data.toString()
        child.stderr.on "data", (data)->
          process.stdout.write data.toString()
    else
      log "The index.coffee doesn't exist."

  keygen: (name)-> 
    log "Keygen is not available for now. Please use Koding > Account > Kite Keys to have one."

  manifest: (key, value)->

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
