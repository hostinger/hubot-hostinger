# Description:
#   Interact with Hostinger API server
#
# Dependencies:
#   none
#
# Configuration:
#   HUBOT_HOSTINGER_API_URL
#
# Commands:
#   hubot hostinger ping - test API is responding
#   hubot hostinger backup list <username> - List backups for username.
#   hubot hostinger backup move <username> - move backup to /home/<username>/public_html
#   hubot hostinger hosted <domain> - check if domain is already hosted
#   hubot hostinger show null routed ips - display currently null routed ips
#
# Author:
#   fordnox

request = require('request')

hostinger_request = (method, url, params, handler) ->
  hostinger_url = process.env.HUBOT_HOSTINGER_API_URL

  request {
    baseUrl: hostinger_url,
    url: url,
    method: method,
    form: params
  },
    (err, res, body) ->
      if err
        console.log "Hostinger says: #{err}"
        return
      content = JSON.parse(body)
      if content.error?
        if content.error?.message
          console.log "Hostinger says: #{content.error.message}"
        else
          console.log "Hostinger says: #{content.error}"
        return
      handler content.result

module.exports = (robot) ->
  robot.respond /hostinger ping/i, (msg) ->
    hostinger_request 'GET', 'ping', null,
      (result) ->
        msg.send result

  robot.respond /hostinger backup list ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'POST', 'admin/backup/account/backups',
      {username: username},
      (result) ->
        if result.length
          for backup in result
            msg.send "#{backup.type} backup #{backup.name} (#{backup.size}) on server #{backup.srv_id}: #{backup.date}"
        else
          msg.send "no backups for #{username}"

  robot.respond /hostinger backup move ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'POST', '/admin/backups/move',
      {username: username},
      (result) ->
        msg.send result

  robot.respond /hostinger hosted ([\S]+)/i, (msg) ->
    domain = msg.match[1]
    hostinger_request 'POST', '/admin/reseller/client/order/is_domain_hosted',
      {domain: domain},
      (result) ->
        if result.hosted
          msg.send "Domain #{result.domain} type #{result.type}: hosted: #{result.hosted}"
        else
          msg.send "Domain #{result.domain} is not hosted"

  robot.respond /hostinger show null routed ips/i, (msg) ->
    hostinger_request 'POST', '/admin/health/null_routed_ips',
      null,
      (result) ->
        msg.send "Ips: #{result}"
