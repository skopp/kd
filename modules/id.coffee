fs = require "fs"
utils = require "../lib/utils"

{ask} = utils

module.exports = class KdId
  constructor: ({@config})->
    @kdIdFile = "#{process.env.HOME}/.kd/koding.key"
  get: ->
    console.log @config.kodingId
  renew: -> 
    ask "Do you really want to do it? It may affect your works! [yes|no]", 
      format: /yes|no|Y|N/,
      callback: (answer)=>
        kdId = utils.keygen 64
        fs.writeFileSync @kdIdFile, kdId
        console.log """
        You have a new key!

        #{kdId}
        """
        process.exit()
      error: (answer)->
        console.log "Please write a valid answer: yes or no. That's simple."
  where: ->
    console.log @kdIdFile