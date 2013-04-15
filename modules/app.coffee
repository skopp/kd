fs = require "fs"
{exec} = require "child_process"
coffee = require "coffee-script"

{log} = console

module.exports = class App
  constructor: ({@config})->
  
  pistachios: /\{(\w*)?(\#\w*)?((?:\.\w*)*)(\[(?:\b\w*\b)(?:\=[\"|\']?.*[\"|\']?)\])*\{([^{}]*)\}\s*\}/g
  
  compile: ->
    manifest = JSON.parse fs.readFileSync "#{process.cwd()}/.manifest"
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
    /* Compiled by KD */
    (function() {
    /* KDAPP STARTS */
    #{source}
    /* KDAPP ENDS */
    }).call();
    """
    fs.writeFileSync "#{process.cwd()}/index.js", mainSource

  create: (name)->
    log "Creating new app is coming very soon..."

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
    unless @config['user.name'] or @config['user.password']
      return log """
      You must define your `user.name` or `user.password`
      to connect your Koding filesystem.

      kd config set user.name <yourusername>
      kd config set user.password <yourpassword>
      """
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