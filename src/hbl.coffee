# Description:
#   Interact with HBL API server
#
# Dependencies:
#   none
#
# Configuration:
#   HUBOT_HBL_APIKEY
#
# Commands:
#   hubot hbl get IPaddress - search for IP in blacklist
#   hubot hbl unban IPaddress - remove ban from blacklist
#
# Author:
#   AlgirdasZ


module.exports = (robot) ->
  robot.hear /hbl get (.*)/i, (msg) ->
    hbl_apikey = process.env.HUBOT_HBL_APIKEY
    user = msg.message.user.name
    IPaddr = escape(msg.match[1])
    robot.http("https://hbl.hostinger.io/api/v1/addresses/" + IPaddr)
    .header('Accept', 'application/json')
    .header('X-API-Key', hbl_apikey)
    .get() (error, response, body) ->
      try
        json = JSON.parse(body)
        if json.IP
          msg.send ":hidethepain: " + "#{json.IP} " + "Banned for " + 
          "#{json.Comment} " + "at: " + "#{json.CreatedAt} by #{json.Author}. FYI: @#{user}\n"
        else
          msg.send ":metal: Nothing found"
      catch error
        msg.send ":coffinpls: something went wrong..."

  robot.hear /hbl unban (.*)/i, (msg) ->
    hbl_apikey = process.env.HUBOT_HBL_APIKEY
    user = msg.message.user.name
    IPaddr = escape(msg.match[1])
    robot.http("https://hbl.hostinger.io/api/v1/addresses/" + IPaddr)
    .header('Accept', 'application/json')
    .header('X-API-Key', hbl_apikey)
    .delete() (error, response, body) ->
      if response.statusCode is 200
        msg.send ":success-kid: " + "#{IPaddr} " + "Ban removed. FYI: @#{user}\n"
      else if response.statusCode is 404
        msg.send ":metal: Not banned"
      else
        msg.send ":confusion: Received #{response.statusCode} status code, not sure what to do with it."
