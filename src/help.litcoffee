Welcome to the `help` module of the bot. As is mentioned in the `server` module, this is a special module which is not even located inside the `modules` directory. This module manages the help information of all the modules and present it to the user.

    Module = require './module'
    module.exports = (commands) ->
      class Help extends Module

Help
---

The `/help` command consumes an argument which is the name of the command that the user needs help with. If no arguemnt is passed, it shows the help information of itself.

        help: (msg, cmd) ->
          if !cmd?
            cmd = 'help'

          cmd = cmd.trim()
          str = 'Not found'

A normal module's help information is stored in its `help` property which is a {command: help} map. But this module, `help`, has no such field. We just hard-code the help information for itself here if no argument is passed or the query is `help`

          if cmd is 'help'
            str = '''
    /help [command]
    Get help for [command]
    '''
          else if commands[cmd]?
            str = commands[cmd].help[cmd]

Then we just send the help information to the user.

          @telegram.sendMessage
            chat_id: msg.chat.id
            text: str
            reply_to_message_id: msg.message_id
            parse_mode: 'markdown'
          .subscribe null, (err) ->
            console.warn err
          , ->
            console.log "Help sent with #{cmd}"

BotFather
---
According to the Telegram rule, bots can register a list of commands and their quick help information to the `@BotFather`. But the list is much to tiring to manually type in, so I wrote this hidden command to generate this information.

        father: (msg) ->
          str = ''
          for k, v of commands

Skip this hidden command itself.

            continue if k is 'father'

All the quick help information are redirected to the `/help` command for my convenience.

            str += "#{k} - Send `/help@#{@telegram.getName()} #{k}` for help\n"

Now send it to the caller.

          @telegram.sendMessage
            chat_id: msg.chat.id
            text: str
          .subscribe null, (err) ->
            console.warn err
