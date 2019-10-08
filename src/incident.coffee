# Description:
#   Interact with DWH API server
#
# Dependencies:
#   none
#
# Configuration:
#   HUBOT_DWH_API_URL
#
# Commands:
#   hubot downtime server_hostname|message|eta|serverIP - add incident to database
#   hubot downtime web000.main-hosting.eu|maintenance|1h|127.0.0.1
#
# Author:
#   edgarasg

request = require('request')

hostinger_request = (method, url, params, handler) ->
  hostinger_url = process.env.HUBOT_DWH_API_URL

  request {
    baseUrl: hostinger_url,
    url: url,
    method: method,
    json: params
  },
    (err, res, body) ->
      if err
        console.log "DWH says: #{err}"
        return
      handler body

module.exports = (robot) ->
  robot.respond /downtime ([^|]*)\|([^|]*)\|(\d\w+)\|?([^|]*)/i, (msg) ->
    server_fqdn = msg.match[1].replace /^\s+|\s+$|http:\/\//g, ''
    message = msg.match[2].replace /^\s+|\s+$/g, ''
    eta = msg.match[3].replace /^\s+|\s+$/g, ''
    server_ip = msg.match[4].replace /^\s+|\s+$/g, ''
    user = msg.message.user.name
    hostinger_request 'POST', 'api/incident',
      {server_fqdn: server_fqdn, server_ip: server_ip, message: message, eta:eta},
      (result) ->
        if result == true
          if server_ip
            robot.messageRoom '#downtime', "Incident: #{server_fqdn} | #{server_ip} | message: #{message} | eta: #{eta} | agent: @#{user}"
          else
            robot.messageRoom '#downtime', "Incident: #{server_fqdn} | message: #{message} | eta: #{eta} | agent: @#{user}"
          msg.send "Incident has been added"
        else
          msg.send "Incident has not been added: #{result}"
