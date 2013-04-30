fs = require "fs"
{exec, spawn} = require "child_process"
coffee = require "coffee-script"

manifest = (username, name)->
  JSON.stringify
    devMode       : true
    version       : "0.1"
    name          : name
    identifier    : "com.koding.apps.#{name}"
    path          : "~/Applications/#{name}.kdapp"
    homepage      : "#{username}.koding.com/#{name}"
    author        : "#{username}"
    repository    : "git://github.com/#{username}/#{name}.kdapp.git"
    description   : "#{name} : a Koding application created with the KD cli."
    category      : "web-app"
    source        :
      blocks      :
        app       :
          files   : [
            "./index.coffee"
          ]
      stylesheets : [
        "./resources/style.css"
      ]
    options       :
      type        : "tab"
    icns          :
      128         : "./resources/icon.128.png"
  , null, 2

{log} = console

module.exports = class App
  constructor: ({@config})->

  pistachios: /\{(\w*)?(\#\w*)?((?:\.\w*)*)(\[(?:\b\w*\b)(?:\=[\"|\']?.*[\"|\']?)\])*\{([^{}]*)\}\s*\}/g

  compile: (path)->
    path ?= process.cwd()
    manifest = JSON.parse fs.readFileSync "#{path}/.manifest"
    files = manifest.source.blocks.app.files
    source = ""

    for file in files
      try
        compiled = coffee.compile(fs.readFileSync(file).toString(), bare: true)
      catch error
        compiled = fs.readFileSync(file).toString()

      block = """
      /* BLOCK STARTS: #{file} */
      #{compiled}
      """
      block = block.replace @pistachios, (pistachio)-> pistachio.replace /\@/g, 'this.'
      source += block

    mainSource = """
    /* Compiled by KD on #{(new Date()).toString()} */
    (function() {
    /* KDAPP STARTS */
    #{source}
    /* KDAPP ENDS */
    }).call();
    """
    fs.writeFileSync "#{path}/index.js", mainSource

  create: (name)->

    {argv: {name, sync}} = @options
      .usage("Creates a Koding Application template")
      .demand(["n"])
      .alias("n", "name")
      .alias("s", "sync")
      .describe("n", "Name of the Kite")
      .describe("s", "Sync kite after creation")

    unless @config['user.name']
      return log """
      I don't know who you are.

      You must define your `user.name`.

      kd config set user.name <yourusername>
      """

    if name.match /[^\w]/
      return log "You mustn't use special chars in kite name."

    appDir = "#{process.cwd()}/#{name}.kdapp"
    tmpFile = "/tmp/koding.kd.app.create.#{Date.now()}"

    # Bash file to run.
    bash = """
    mkdir -p #{appDir}
    touch #{appDir}/.manifest
    touch #{appDir}/ChangeLog
    touch #{appDir}/README
    touch #{appDir}/index.coffee
    mkdir -p #{appDir}/resources
    touch #{appDir}/resources/style.css
    cd #{appDir}/resources
    wget https://koding.com/images/default.app.thumb.png
    mv #{appDir}/resources/default.app.thumb.png #{appDir}/resources/icon.128.png 
    """

    fs.writeFileSync tmpFile, bash
    log "Creating #{name}.kdapp..."

    exec "bash #{tmpFile}", =>
      fs.writeFileSync "#{appDir}/.manifest", manifest(@config['user.name'], name)
      if sync
        process.chdir appDir
        @sync()


  sync: ->
    unless process.cwd().match /\.kdapp$/
      return log """
      You are not in an application directory. Application directory names
      must end with `.kdapp` extension.

      Like that example:

      mkdir appname.kdapp
      cd appname.kdapp
      """
    try
      manifest = JSON.parse fs.readFileSync "#{process.cwd()}/.manifest"
    catch error
      return log """
      You have to create a manifest file.
      """
    unless manifest
      return log """
      You are not in an application directory.
      """

    requirePassword = ->
      log """
      You must define your `user.name` and `user.password`
      to connect your Koding filesystem.

      kd config set user.name <yourusername>
      kd config set user.password <yourpassword>
      """

    unless @config['user.password'] then return requirePassword()
    unless @config['user.password'] then return requirePassword()
    
    log "Connecting your Koding filesystem, please wait..."

    ftps = require "ftps"
    connection = new ftps
      host      : "ftps.koding.com"
      username  : @config['user.name']
      password  : @config['user.password']
      protocol  : "ftps"
    connection
    .raw("set ssl:verify-certificate no")
    .cd("Applications")
    .raw("mirror -Ren #{process.cwd()}")
    .exec (err, {_err, data})->
      log data