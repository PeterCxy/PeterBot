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
      .on 'complete', check (res) ->
        console.log "Help sent with #{cmd}" if res?
