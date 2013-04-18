{exec} = require "child_process"
{log} = console

module.exports = class Install
  @help: """
  Koding KD CLI Installer Tool
  """

  module: (module)->
    log "Installing #{module}"
