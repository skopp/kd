fs = require "fs"
{exec, spawn} = require "child_process"
Progress = require "progress"
{log} = console

module.exports = class Install
  
  help: """
  Koding KD CLI Installer Tool
  """

  __command: (url)->

    cwd = process.cwd()
    fragments = url.split /\/+/
    [username, repository] = fragments.slice -2

    progress = new Progress 'Downloading: [:bar] :percent :etas', 
      total: 3
      incomplete: " "
      width: 20

    tempFile = "/tmp/koding.kd.get.#{new Date()}"
    bash = """
    mkdir -p #{cwd}/kites/
    git clone --recursive #{url} #{cwd}/kites/#{username}/#{repository}
    """
    fs.writeFileSync tempFile, bash
    clone = spawn "bash", [tempFile]
    clone.stdout.on "data", (data)-> progress.tick()
    clone.stderr.on "data", (data)-> progress.tick()
    clone.stdout.on "close", ->
      progress.tick(progress.total - progress.curr)
      process.exit()

