fs = require "fs"
url = require "url"
YAML = require "js-yaml"
Progress = require "progress"
request = require "request"

{spawn, exec} = require "child_process"
{log} = console
{ask} = require "../lib/utils"

module.exports = class Kite

  alias:
    "new": "create"
    "i": "install"

  help:"""
  Kites are simply web services for Koding.
  You can share your kites over internet.
  """

  keys: {}

  constructor: ({@config})->
    @keysFile = "#{process.env.HOME}/.kd/.keys.yml"
    try
      @keys = require @keysFile
    catch error
      fs.writeFileSync @keysFile, ""
      @keys = {}

  wizard: ->

    log """
    Kites are simply web services for Koding. You can write, manage and share
    your kites. When you start a Kite, it'll be online.

    Awesome, right?
    We think so.

    Now, let's create a kite together. Please answer following questions.

    First of all we need a name. It should be simple and meaningful. We like
    lowercase names.
    """

    step1 = =>
      ask "What is your Kite's name?",
        format: /^[\w\_]+$/
        callback: (name)=> 
          @create {name}
        error: (name)->
          log """
          
          Ok, then. It seems you've entered wrong name. Try again.
          This time find better than "#{name}".
          So,
          """

    step1()

  create: (argv)->

    unless typeof argv is "object"
      {argv: {name, domain}} = @options
        .usage("Creates a Kite template")
        .demand(["n"])
        .alias("n", "name")
        .alias("d", "domain")
        .describe("n", "Name of the Kite")
        .describe("d", "Domain of the Kite, for debug")
    else
      {name} = argv
    
    if name.match /[^\w]/
      return log "You mustn't use special chars in kite name."

    kiteDir = "#{process.cwd()}/#{name}.kite"
    tmpFile = "/tmp/koding.kd.kite.create.#{Math.random()}"

    # Bash file to run.
    # TODO: write full paths
    bash = """
    mkdir -p #{kiteDir}
    cd #{kiteDir}
    touch #{kiteDir}/.manifest.yml
    touch #{kiteDir}/index.coffee
    mkdir -p #{kiteDir}/resources
    touch #{kiteDir}/resources/key.coffee
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
    yaml          = require "js-yaml"
    Kite          = require "kd-kite"
    rope          = require "kd-rope"
    key           = require "./resources/key"

    manifest      = require "./.manifest.yml"
    manifest      = key manifest

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
      name      : name or 'Untitled'
      apiAdress : domain or 'http://localhost:3000'

    keyFile = """
    fs = require "fs"
    module.exports = (manifest)->
      try
        key = fs.readFileSync "\#{process.env.HOME}/.kd/kites/\#{manifest.name}.key"
        manifest.key = key
      catch error
        console.log "Your kite seems unregistered. You need to register it."
        console.log "Please run: kd kite register -n \#{manifest.name} --save"
        process.exit()
      manifest
    """

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
      fs.writeFileSync "#{kiteDir}/resources/key.coffee", keyFile
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
      deps = if repos then repos else require("#{cwd}/.manifest.yml").dependencies
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

    try
      manifestFile = "#{process.cwd()}/.manifest.yml"
      manifest = require manifestFile
    catch error
      throw "You are not in a kite directory!"

    if manifest.type is "web"

      x = request.post "http://kontrol.in.koding.com/proxies/proxy.in.koding.com/services/#{manifest.name}",
        body: JSON.stringify
          rabbitkey: @config.kodingId
          key: String(manifest.version)
          host: manifest.host
      , (err, res, body)->
        if err then log "An error occured. #{err.message}"
        log """
        Probably successful! Your #{manifest.host} is public now.

        Try opening http://#{manifest.name}-#{manifest.version}.x.kd.io
        """
    else
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
          nohup coffee `dirname $manifest`/index.coffee
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

  manifest: (key, value)->
    manifestFile = "#{process.cwd()}/.manifest.yml"
    manifest = require manifestFile
    unless value
      log manifest[key]
    else
      manifest[key] = value
      manifestData = YAML.dump manifest
      fs.writeFileSync manifestFile, manifestData

  key: (name, key)->
    @keys or= {}
    @keys[name] = key
    fs.writeFileSync @keysFile, YAML.dump @keys

  register: ->
    {argv: {name, save}} = @options
      .usage("Registers your Kite and give you a key.")
      .demand(["n"])
      .alias("n", "name")
      .describe("n", "Name of the Kite")
      .describe("save", "Save the Kite key")

    unless @config['user.password']
      return log """
      You have to set your user.password.

      kd config set user.password <yourpass>
      """

    unless @config['user.name']
      return log """
      You have to set your user.password.

      kd config set user.password <yourpass>
      """

    request.post "http://localhost:3000/-/kite/register",
      form:
        username: @config["user.name"]
        password: @config["user.password"]
        kiteName: name
    , (err, res, body)->

      if err then log "An error occured. #{e.message}"

      response = JSON.parse body
      if response.error
          log "[Koding:kite] ERROR: #{response.error}"
        else
          if save
            exec "mkdir -p #{process.env.HOME}/.kd/kites/", ->
              fs.writeFileSync "#{process.env.HOME}/.kd/kites/#{response.kiteName}.key", response.key
          log response.key

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
