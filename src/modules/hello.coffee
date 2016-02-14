Rx = require 'rxjs/Rx'
printf = require 'printf'
{grabOnce, release, cleanup} = require '../server'

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
  cancel: (msg) -> cleanup msg
  remind: (msg) ->
    parse = require 'parse-duration'

    @telegram.sendMessage
      chat_id: msg.chat.id
      text: "What to remind you of?"
      reply_to_message_id: msg.message_id
    .flatMap (it) -> grabOnce msg
    .flatMap (it) =>
      o = @telegram.sendMessage
        chat_id: msg.chat.id
        text: "Good. Now tell me when to remind you. Please reply in this format: AhBmCsDms. e.g. 10s, 1m20s"
        reply_to_message_id: it.message_id
      Rx.Observable.of it.text
        .zip o, (x, y) -> [x, y]
    .flatMap (it) ->
      Rx.Observable.of it[0]
        .zip (grabOnce msg), (x, y) -> [x, y]
    .map (it) -> [it[0], parse it[1].text]
    .catch (err) -> Rx.Observable.of [err.message, 100]
    .flatMap (it) =>
      # Tell the user
      o = @telegram.sendMessage
        chat_id: msg.chat.id
        text: "Yes, sir!"
        reply_to_message_id: msg.message_id

      Rx.Observable.of it
        .zip o, (x, y) -> x
    .flatMap (it) ->
      Rx.Observable.of it[0]
        .delay new Date Date.now() + it[1]
    .flatMap (it) =>
      @telegram.sendMessage
        chat_id: msg.chat.id
        text: "@#{msg.from.username} #{it}"
    .subscribe null, null, ->
      console.log "Reminded @#{msg.from.username}"


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
    cancel: '/cancel - Cancel the current operation'
    remind: '/remind - Just a reminder. This is an interactive command, so just try to use it.'
