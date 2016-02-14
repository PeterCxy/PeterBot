# The /help command
{check} = require './utility'

module.exports = (commands) ->
  require('./builder').build
    help: (msg, cmd) ->
      if !cmd?
        cmd = 'help'

      cmd = cmd.trim()
      str = 'Not found'
      if cmd is 'help'
        str = '''
/help [command]
Get help for [command]
'''
      else if commands[cmd]?
        str = commands[cmd].help[cmd]

      @telegram.sendMessage
        chat_id: msg.chat.id
        text: str
        reply_to_message_id: msg.message_id
        parse_mode: 'markdown'
      .subscribe null, (err) ->
        console.warn err
      , ->
        console.log "Help sent with #{cmd}"

    # Generate command list for the BotFather
    father: (msg) ->
      str = ''
      for k, v of commands
        continue if k is 'father'
        str += "#{k} - Send `/help@#{@telegram.getName()}` #{k} for help\n"
      @telegram.sendMessage
        chat_id: msg.chat.id
        text: str
      .subscribe null, (err) ->
        console.warn err
