# Support for correction like s/AAA/BBB/g
module.exports = require('../builder').build
  generic: (msg) ->
    if /^s\/.*\/.*(\/g)?$/.test msg.text
      last = @get msg.chat.id, msg.from.id, 'last'
      last = msg.reply_to_message.text if msg.reply_to_message?
      return if !last?

      sub = (msg.text + '/').split '/'
      res = last.replace (new RegExp sub[1], sub[3]), sub[2]

      @telegram.sendMessage
        chat_id: msg.chat.id,
        text: "@#{msg.from.username} meant to say: #{res}",
        reply_to_message_id: msg.message_id
      .subscribe null, null, ->
        console.log "@#{msg.from.username} meant to say: #{res}"
    else
      @put msg.chat.id, msg.from.id, 'last', msg.text
