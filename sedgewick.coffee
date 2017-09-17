
request  = require 'request'
{Client} = require 'discord.io'
interval = null
commands = {}

bot = new Client
  token: process.env.token
  messageCacheLimit: 0

# Reconnect on disconnect
bot.on 'disconnect', ->
  bot.connect()

# Set reload interval
bot.on 'ready', ->
  clearInterval interval if interval?
  interval = setInterval reload, 1e4
  reload()

# Handle messages
bot.on 'message', (..., {d: event}) ->
  {content: command} = event
  return unless command[0] is '!'

  command = command[1 ..].trim()
  command = command.toLowerCase()
  return unless command of commands

  # Allowed?
  bot.deleteMessage
    channelID: event.channel_id
    messageID: event.id

  commands[command] event, command

# Welcome message
bot.on 'guildMemberAdd', (..., {d: event}) ->
  bot.sendMessage
    to: process.env.general_id
    message:
      "
      Welcome <@#{event.user.id}>!
      Read <##{process.env.information_id}>.
      "

# Reload method
reload = ->
  request
    url: process.env.steam
    json: on, timeout: 2e4,
    presence

# Update presence callback
presence = (error, ..., data) ->
  return console.error error if error
  return unless data?.response?
  {response: {player_count: count}} = data
  bot.setPresence game: name: "w/ #{count} Plebeians"

# Help command
commands.h =
commands.help = (event) ->
  bot.sendMessage
    to: event.author.id,
    message:
      """
      **Commands:**

      __Continental roles__ (max 1)
      ```yaml
      !eu - Europe
      !oc - Oceania
      !na - North America
      !sa - South America
      !an - Antarctica
      !af - Africa
      !as - Asia
      ```
      __Captains role__ (read topic in <##{process.env.captains_id}>)
      ```yaml
      !captaineer
      ```
      """

# Enable / disable a role
shift = (event, command, callback) ->
  server = bot.servers[process.env.server_id]
  {roles} = server.members[event.author.id]

  # Remove if existing
  for role_id in roles
    role = server.roles[role_id]
    name = role.name.toLowerCase()
    continue unless name is command

    bot.removeFromRole
      serverID: process.env.server_id
      userID: event.author.id
      roleID: role_id

    return

  # Add if inexistant
  for role_id, role of server.roles
    name = role.name.toLowerCase()
    continue if name isnt command

    bot.addToRole
      serverID: process.env.server_id
      userID: event.author.id
      roleID: role_id,
      callback

    return

# Captaineer command
commands.captaineer = shift

# Continent commands
continents = [
  'af', 'an', 'as'
  'eu', 'na', 'oc'
  'sa']

# Continent commands
for continent in continents
  commands[continent] = ->
    shift arguments ...,
      (reevaluate.bind null, arguments ...)

# Reevaluate continent roles
reevaluate = (event, command) ->
  server = bot.servers[process.env.server_id]
  {roles} = server.members[event.author.id]

  for role_id in roles
    role = server.roles[role_id]
    name = role.name.toLowerCase()
    continue unless name in continents
    continue if name is command

    bot.removeFromRole
      serverID: process.env.server_id
      userID: event.author.id
      roleID: role_id


bot.connect()
