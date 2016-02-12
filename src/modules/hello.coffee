Rx = require 'rxjs/Rx'
printf = require 'printf'

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
  choose: (msg, format, args...) ->
    Rx.Observable.from args
      .map (it) ->
        if /^[0-9]+\-[0-9]+$/.test it
          [min, max] = it.split '-'
          [min, max] = [(parseInt min), (parseInt max)]
          Math.random() * (max - min) + min
        else
          a = it.split ';'
          a[Math.floor Math.random() * a.length]
      .toArray()
      .map (it) -> printf format, it...
      .flatMap (it) =>
        @telegram.sendMessage
          chat_id: msg.chat.id
          text: it
          reply_to_message_id: msg.message_id
      .subscribe null, null, ->
        console.log "Formatted #{format}"

  help:
    hello: '/hello - Just send "hello"'
    echo: '/echo .... - Echo everything'
    choose: '''
/choose format choice1-1;choice1-2;... choice2-1;choice2-2;... ...
Choose one from each group of choices and fill them into `format` using printf.
Alternatively, if your choices are made up of numbers, you can use `min-max` as choices.
e.g.
```
  /choose %s:%d%% Lucky;Unlucky 0-100
```
'''
