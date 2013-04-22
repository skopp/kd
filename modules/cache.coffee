{exec} = require "child_process"

module.exports = class Cache
  clean: ->
    exec "rm -f /tmp/koding.kd*"