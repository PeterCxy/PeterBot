Everybody may run into typos. This module provides __sed-like__ syntax to correct the user's previously sent messages.

To make this actually work, this module must be registered as a generic processor.

    module.exports = require('../builder').build
      generic: (msg) ->

If a message is something like `s/a/b(/g)`, it is considered a mark to correct the user's last message.

        if /^s\/.*\/.*(\/gi?)?$/.test msg.text

Pull the last message sent by the user in the current chat. However, if the correction request replies to another message, we then correct that message no matter whether the message is sent by the user who requested the correction. This is for fun.

          last = @get msg.chat.id, msg.from.id, 'last'
          last = msg.reply_to_message.text if msg.reply_to_message?
          return if !last?

The last part `/g`, `/gi` etc. can be omitted, for which we may run into overflows. As a dirty hack, we add a `/` to the end of the string and then split it with `/`. This ensures that the string is splitted into at least 4 parts. Then, we build a `RegExp` out of it, and use it to correct the original message.

          sub = (msg.text + '/').split '/'
          res = try
            last.replace (new RegExp sub[1], sub[3]), sub[2]
          catch e
            e

          @telegram.sendMessage
            chat_id: msg.chat.id,
            text: "@#{msg.from.username} meant to say: #{res}",
            reply_to_message_id: msg.message_id
          .subscribe null, null, ->
            console.log "@#{msg.from.username} meant to say: #{res}"

If the message is not a correction request, we just store it, in case that it might be needed afterwards for correction.

        else
          @put msg.chat.id, msg.from.id, 'last', msg.text
