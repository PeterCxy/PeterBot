{check} = require '../utility'

module.exports = require('../builder').build
  hello: (msg) ->
    @telegram.sendMessage
      chat_id: msg.chat.id
      text: "Hello, @#{msg.from.username}"
    .on 'complete', check ->
      console.log "Hello message sent to @#{msg.from.username}"
  echo: (msg, args...) ->
    str = args.join ' '
    @telegram.sendMessage
      chat_id: msg.chat.id
      text: str
    .on 'complete', check ->
      console.log "Echoed '#{str}'"

  help:
    hello: '/hello - Just send "hello"'
    echo: '/echo .... - Echo everything'
