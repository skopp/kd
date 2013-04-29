fs = require "fs"
url = require "url"
{exec, spawn} = require "child_process"
Progress = require "progress"
{log} = console

module.exports = class Install
  
  help: """
  Koding KD CLI Installer Tool
  """

  __command: (repo)->

    cwd = process.cwd()
    fragments = repo.split /\/+/
    [username, repository] = fragments.slice -2

    unless username and repository
      throw "#{repo} doesn't look like an repo"

    repoDefaults =
      protocol: 'https'
      hostname: 'github.com'
    
    parsed = url.parse(repo)
    
    repo = url.format repoDefaults extends parsed

    console.log "[Koding:get] Found: #{repo}"

    progress = new Progress "[Koding:get] Downloading: [:bar] :percent :etas", 
      total: 3
      incomplete: " "
      width: 20

    tempFile = "/tmp/koding.kd.get.#{Math.random()}"
    bash = """
    mkdir -p #{cwd}/kites/
    git clone --recursive #{repo} #{cwd}/kites/#{username}/#{repository}
    """
    fs.writeFileSync tempFile, bash
    clone = spawn "bash", [tempFile]
    clone.stdout.on "data", (data)-> progress.tick()
    clone.stderr.on "data", (data)-> progress.tick()
    clone.stdout.on "close", ->
      progress.tick(progress.total - progress.curr)
      process.exit()

