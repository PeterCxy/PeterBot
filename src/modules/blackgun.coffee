module.exports = require('../builder').build
  generic: (msg) ->
    for gun in guns
      cond = gun.cond msg
      if cond? and cond
        @telegram.sendMessage
          chat_id: msg.chat.id
          text: gun.act cond, msg
          reply_to_message_id: msg.message_id
        .subscribe null, null, ->
          console.log "Gun activated to #{msg.from.username}"
        break

guns = [
    cond: (msg) -> msg.text.match /#RICH/g
    act: -> '#POOR'
  ,
    cond: (msg) -> msg.text.match /\uD83C\uDF1A/g
    act: (cond) -> "\uD83C\uDF1D".repeat cond.length
]
