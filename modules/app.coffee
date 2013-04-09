fs = require "fs"
{exec} = require "child_process"
coffee = require "coffee-script"

module.exports = class App
  constructor: (@config)->
  
  pistachios: /\{(\w*)?(\#\w*)?((?:\.\w*)*)(\[(?:\b\w*\b)(?:\=[\"|\']?.*[\"|\']?)\])*\{([^{}]*)\}\s*\}/g
  
  compile: ->
    manifest = JSON.parse fs.readFileSync "#{process.cwd()}/.manifest"
    files = manifest.source.blocks.app.files
    source = ""
    
    for file in files
      block = """
      /* BLOCK STARTS: #{file} */
      #{coffee.compile(fs.readFileSync(file).toString())}
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
