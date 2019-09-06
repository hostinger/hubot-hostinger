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
#   hubot hostinger backup prepare <username> <backup_name> - Prepare backups for username.
#   hubot hostinger backup create <username> - Create backup for <username>
#   hubot hostinger backup mount <username> - Mount backup dir in user home dir
#   hubot hostinger backup unmount <username> - Unmount backup dir
#   hubot hostinger backup mount-status <username> - Check if backup dir is mounted or not
#   hubot hostinger hosted <domain> - Check if domain is already hosted
#   hubot hostinger check <server_id> <ip> - Check if ip <ip> blocked on <server_id>
#   hubot hostinger unban <server_id> <ip> - Unban ip <ip> blocked on <server_id>
#   hubot hostinger account info <username> - Get account info for username
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
            msg.send "#{backup.type} (preparing: #{backup.preparing}) : #{backup.name} (#{backup.size}) - #{backup.url} (link is clickable one time only)"
        else
          msg.send "no backups for #{username}"

  robot.respond /hostinger backup prepare ([a-z0-9 _\.]+)/i, (msg) ->
    username = msg.match[1].split(" ")[0]
    backup_name = msg.match[1].split(" ")[1]
    hostinger_request 'POST', 'admin/backup/account/backup/prepare',
      {username: username,backup_name: backup_name},
      (result) ->
        if result.length
          msg.send result
        else
          msg.send "no backups for #{username}"

  robot.respond /hostinger backup mount ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'POST', 'admin/backup/account/backup/mount',
      {username: username},
      (result) ->
        if result == true
          msg.send "Backup dir has been mounted"
        else
          msg.send "Backup dir is probably already mounted, please check"

  robot.respond /hostinger backup unmount ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'POST', 'admin/backup/account/backup/unmount',
      {username: username},
      (result) ->
        if result == true
          msg.send "Backup dir has been unmounted"
        else
          msg.send "Backup dir is not mounted"

  robot.respond /hostinger backup mount-status ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'POST', 'admin/backup/account/backup/mount_status',
      {username: username},
      (result) ->
        if result == true
          msg.send "Backup dir is mounted"
        else
          msg.send "Backup dir is not mounted"

  robot.respond /hostinger backup create ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'POST', 'admin/backup/account/backup/create',
      {username: username},
      (result) ->
        msg.send result

  robot.respond /hostinger hosted ([\S]+)/i, (msg) ->
    domain = msg.match[1]
    hostinger_request 'POST', 'admin/reseller/client/order/is_domain_hosted',
      {domain: domain},
      (result) ->
        if result.hosted
          msg.send "Domain #{result.domain} type #{result.type}: hosted: #{result.hosted}"
        else
          msg.send "Domain #{result.domain} is not hosted"

  robot.respond /hostinger check ([0-9\. ]+)/i, (msg) ->
    server_id = msg.match[1].split(" ")[0]
    ip = msg.match[1].split(" ")[1]
    hostinger_request 'POST', 'admin/server/ip/check',
      {server_id: server_id,ip: ip},
      (result) ->
        if result.length
          msg.send "#{result}"
        else
          msg.send "Nothing"

  robot.respond /hostinger unban ([0-9\. ]+)/i, (msg) ->
    server_id = msg.match[1].split(" ")[0]
    ip = msg.match[1].split(" ")[1]
    hostinger_request 'POST', 'admin/server/ip/unban',
      {server_id: server_id,ip: ip},
      (result) ->
        if result.length
          msg.send "#{result}"
        else
          msg.send "Nothing"

  robot.respond /hostinger account info ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request 'GET', 'admin/reseller/client/account/'+username+'/info',
      null,
      (result) ->
        msg.send JSON.stringify(result, null, '\t')
