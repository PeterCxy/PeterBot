module.exports = require('../builder').build
  hello: (msg) ->
    @telegram.sendMessage
      chat_id: msg.chat.id
      text: "Hello, @#{msg.from.username}"
    .subscribe null, null, ->
      console.log "Hello message sent to @#{msg.from.username}"
  echo: (msg, args...) ->
    str = args.join ' '
    @telegram.sendMessage
      chat_id: msg.chat.id
      text: str
    .subscribe null, null, ->
      console.log "Echoed '#{str}'"

  help:
    hello: '/hello - Just send "hello"'
    echo: '/echo .... - Echo everything'
