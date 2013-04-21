fs = require "fs"
http = require "http"

module.exports = class Auth

  help: """
  Kite authentication things.
  """
  constructor: ({@config})->
    @username = @config['user.name']

  login: ->
    unless @username
      throw """
      You must define a username using `kd config`

      Usage: kd config set user.name yourusername
      """
    sshKey = fs.readFileSync "#{process.env.HOME}/.ssh/id_rsa.pub"
    sshKey = sshKey.toString().replace /^\s+|\s+$/g, ''
    request = http.request 
      hostname: "localhost"
      port: 3000
      path: "/-/sshkey/login/#{@username}"
      method: "POST",
      (response)->
        response.setEncoding "utf8"
        response.on "data", (chunk)->
          console.log chunk
    request.write sshKey
    request.end()
