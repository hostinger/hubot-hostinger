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
#   hubot hostinger backup restoredb <username> <database_name> <archive_name> - Restore database backup
#   hubot hostinger backup restorefiles <username> <archive_name> <wipe (default: 1, 1(true) or 0(false) , OPTIONAL)> <path (default: / , OPTIONAL)> - Restore files backup
#   hubot hostinger hosted <domain> - Check if domain is already hosted
#   hubot hostinger check <server_id> <ip> - Check if ip <ip> blocked on <server_id>
#   hubot hostinger unban <server_id> <ip> - Unban ip <ip> blocked on <server_id>
#   hubot hostinger boost <username> - Temporary increase account limits for faster archive extract and files copy
#   hubot hostinger stopboost <username> - Reset account limits to default after using `boost` command
#   hubot hostinger moncli_check <username> - Check Hostinger account for any misconfigurations.
# Author:
#   fordnox

request = require('request')
hostinger_request = (msg, method, url, params, handler) ->
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
          msg.reply content.error.message
          return
        else
          console.log "Hostinger says: #{content.error}"
      handler content.result

module.exports = (robot) ->
  robot.respond /hostinger ping/i, (msg) ->
    hostinger_request 'GET', 'ping', null,
      (result) ->
        msg.send result

  robot.respond /hostinger backup list ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/backup/account/backups',
      {username: username},
      (result) ->
        if result.length
           array = []
           for backup in result
             array.push "archive_name: #{backup.archive} (preparing: #{backup.preparing}) backup_name: #{backup.name} (#{backup.size}) - #{backup.url} (link is clickable one time only)"
           if array.length > 250
             filename = "backuplist.txt"
             opts = {
             content: array.join("\n")
             title: 'Backup List'
             channels: msg.message.room
             }
             robot.adapter.client.web.files.upload(filename, opts)
           else
             msg.send array.join("\n")
        else
          msg.send "no backups for #{username}"

  robot.respond /hostinger backup prepare ([a-z0-9 _\.]+)/i, (msg) ->
    username = msg.match[1].split(" ")[0]
    backup_name = msg.match[1].split(" ")[1]
    hostinger_request msg, 'POST', 'admin/backup/account/backup/prepare',
      {username: username,backup_name: backup_name},
      (result) ->
        if result.length
          msg.send result
        else
          msg.send "no backups for #{username}"

  robot.respond /hostinger backup mount ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/backup/account/backup/mount',
      {username: username},
      (result) ->
        if result == true
          msg.send "Backup dir has been mounted"
        else
          msg.send "Backup dir is probably already mounted, please check"

  robot.respond /hostinger backup unmount ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/backup/account/backup/unmount',
      {username: username},
      (result) ->
        if result == true
          msg.send "Backup dir has been unmounted"
        else
          msg.send "Backup dir is not mounted"

  robot.respond /hostinger backup mount-status ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/backup/account/backup/mount_status',
      {username: username},
      (result) ->
        if result == true
          msg.send "Backup dir is mounted"
        else
          msg.send "Backup dir is not mounted"

  robot.respond /hostinger backup create ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/backup/account/backup/create',
      {username: username},
      (result) ->
        msg.send "#{result}"

  robot.respond /hostinger backup restoredb ([a-z0-9 -_\.]+)/i, (msg) ->
    username = msg.match[1].split(" ")[0]
    db_name = msg.match[1].split(" ")[1]
    archive = msg.match[1].split(" ")[2]
    hostinger_request msg, 'POST', 'admin/account/restore/database',
      {username: username,db_name: db_name,archive: archive},
      (result) ->
        if result == true
          msg.send "Restored"
        else
          msg.send result

  robot.respond /hostinger backup restorefiles ([a-z0-9 -_\.]+)/i, (msg) ->
    username = msg.match[1].split(" ")[0]
    archive = msg.match[1].split(" ")[1]
    wipe = msg.match[1].split(" ")[2]
    path = msg.match[1].split(" ")[3]
    hostinger_request msg, 'POST', 'admin/account/restore/files',
      {username: username,archive: archive,wipe: wipe,path: path},
      (result) ->
        if result == true
          msg.send "Restored"
        else
          msg.send result

  robot.respond /hostinger hosted ([\S]+)/i, (msg) ->
    domain = msg.match[1]
    hostinger_request msg, 'POST', 'admin/reseller/client/order/is_domain_hosted',
      {domain: domain},
      (result) ->
        if result.hosted
          msg.send "Domain #{result.domain} type #{result.type}: hosted: #{result.hosted}"
        else
          msg.send "Domain #{result.domain} is not hosted"

  robot.respond /hostinger check ([0-9\. ]+)/i, (msg) ->
    server_id = msg.match[1].split(" ")[0]
    ip = msg.match[1].split(" ")[1]
    hostinger_request msg, 'POST', 'admin/server/ip/check',
      {server_id: server_id,ip: ip},
      (result) ->
        if result.length
          msg.send "#{result}"
        else
          msg.send "Nothing"

  robot.respond /hostinger unban ([0-9\. ]+)/i, (msg) ->
    server_id = msg.match[1].split(" ")[0]
    ip = msg.match[1].split(" ")[1]
    hostinger_request msg, 'POST', 'admin/server/ip/unban',
      {server_id: server_id,ip: ip},
      (result) ->
        if result.length
          msg.send "#{result}"
        else
          msg.send "Nothing"

  robot.respond /hostinger boost ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/account/high-io/set',
      {username: username},
      (result) ->
        if result == true
          msg.send "The account has been BOOSTED!"
        else
          msg.send "ERROR"

  robot.respond /hostinger stopboost ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/account/high-io/unset',
      {username: username},
      (result) ->
        if result == true
          msg.send "The Boost has been stopped"
        else
          msg.send "ERROR"

  robot.respond /hostinger moncli_check ([a-z0-9]+)/i, (msg) ->
    username = msg.match[1]
    hostinger_request msg, 'POST', 'admin/account/moncli/check',
      {username: username},
      (result) ->
        if result.length
          msg.send "#{result}"
        else
          msg.send "Nothing"
