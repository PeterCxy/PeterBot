Rx = require 'rxjs/Rx'
module.exports = require('../builder').build
  generic: (msg) ->
    Rx.Observable.from guns
      .map (it) -> [(it.cond msg), it.act]
      .filter (it) -> it[0]? and it[0]
      .take 1
      .flatMap (it) =>
        @telegram.sendMessage
          chat_id: msg.chat.id
          text: it[1](it[0], msg)
          reply_to_message_id: msg.message_id
      .subscribe null, (err) ->
        console.log "Gun failed to activate to #{msg.from.username}: #{err}"

guns = [
    cond: (msg) -> msg.text.match /#RICH/gi
    act: -> '#POOR'
  ,
    cond: (msg) -> msg.text.match /#POOR/gi
    act: -> '#RICH'
  ,
    cond: (msg) -> (msg.text.match /\uD83C\uDF1A/g)?.filterLessThan 2
    act: (cond) -> "\uD83C\uDF1D".repeat cond.length
  ,
    cond: (msg) -> (msg.text.match /\uD83C\uDF1D/g)?.filterLessThan 2
    act: (cond) -> "\uD83C\uDF1A".repeat cond.length
]
