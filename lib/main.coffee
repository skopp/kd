module.exports = class KodingCLI

  constructor: (@module, @command, @params)->
    @root = process.cwd()
    try
      @moduleClass = require "#{__dirname}/../modules/#{module}"
    catch e
      console.log "[Koding] ERROR: Module #{module} not found."
      return

    unless @command
      console.log "[Koding:#{module}] INFO: Displaying help text."
      console.log @moduleClass.help
      return

    try
      @moduleInstance = new @moduleClass
    catch e
      console.log "[Koding:#{module}] ERROR: Module instance couldn't be created."
      return

    unless @moduleInstance[@command]
      console.log "[Koding:#{module}] ERROR: Command #{command} not found."
      return

    try
      @moduleInstance[@command] @params...
    catch error
      console.log "[Koding:#{module}] EXCEPTION: #{error.message or error}"

  @run: (coffeeBin, file, module, command, params...) => new @ module, command, params