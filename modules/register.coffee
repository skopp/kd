fs = require "fs"
utils = require "../lib/utils"

{ask} = utils

module.exports = class Register

  KD_DIR = "#{process.env.HOME}/.kd"

  constructor: ({@config})->
    @privateKeyPath = "#{KD_DIR}/koding.key"
    @publicKeyPath = "#{KD_DIR}/koding.key.pub"
  get: ->
    console.log @config.publicKey
  renew: ->

    {argv: {all, silent}} = @options

    change = (path, name)=>
      key = utils.keygen 64
      fs.writeFileSync path, key
      console.log "#{name}: #{key}"

    unless silent
      ask "Do you really want to do it? It may affect your works! [yes|no]", 
        format: /yes|no|Y|N/,
        callback: (answer)=>
          if answer is "yes"
            change @publicKeyPath, "Public"
            if all then change @privateKeyPath, "Private"
          process.exit()
        error: (answer)->
          console.log "Please write a valid answer: yes or no. That's simple."
    else
      change @publicKeyPath, "Public"
      if all then change @privateKeyPath, "Private"
  where: ->
    console.log @publicKeyPath

  link: ->
    link = "https://koding.com/-/kd/register/#{@config.publicKey}"
    console.log """
    Please open following URL via browser:
    
    #{link}"""