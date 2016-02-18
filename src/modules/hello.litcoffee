The `Hello, world` and misc module for the bot.

    Rx = require 'rxjs/Rx'
    printf = require 'printf'
    {grabOnce, release, cleanup} = require '../server'

    module.exports = require('../builder').build

Hello
---
Just send `hello` to a user.

      hello: (msg) ->
        @telegram.sendMessage
          chat_id: msg.chat.id
          text: "Hello, @#{msg.from.username}"
        .subscribe null, null, ->
          console.log "Hello message sent to @#{msg.from.username}"

Echo
---
Mimick the input arguments.

      echo: (msg, args...) ->
        str = args.join ' '
        @telegram.sendMessage
          chat_id: msg.chat.id
          text: str
        .subscribe null, null, ->
          console.log "Echoed '#{str}'"

Choose
---
It consumes unlimited arguments. The first argument is a printf-like format string, and the rest are called `choices`. Every other argument is a list of available choices divided with `;`. Each placeholder in the first argument corresponds with a list of choices. When called, the command will choose one from each list of arguments and fill them into the placeholders.

      choose: (msg, format, args...) ->
        Rx.Observable.from args
          .map (it) ->

However, if a list of choices is in the format of `min-max`, it is a `range list`. We will randomly choose one number within the range as the result. It is a float number, so in order to get a correct output, you may need to specify the number format in the `format` string.

            if /^[0-9]+\-[0-9]+$/.test it
              [min, max] = it.split '-'
              [min, max] = [(parseInt min), (parseInt max)]
              Math.random() * (max - min) + min

Otherwise, just randomly choose one from the list.

            else
              a = it.split ';'
              a[Math.floor Math.random() * a.length]

Convert the results to an array and use `printf` module to fill the placeholders.

          .toArray()
          .map (it) -> printf format, it...
          .flatMap (it) =>
            @telegram.sendMessage
              chat_id: msg.chat.id
              text: it
              reply_to_message_id: msg.message_id
          .subscribe null, null, ->
            console.log "Formatted #{format}"

Cancel
---
Cancel the current input handler. See the `server` module for more details on the `cleanup` function.

      cancel: (msg) -> cleanup msg

Remind
---
This is a reminder command. It takes no arguments, but use input handlers to ask the user for inputs. This is an example for the `grab` function in the `server` module. Note that the whole method is based on __streaming__, so there might be some workarounds for some special needs.

      remind: (msg) ->
        parse = require 'parse-duration'

First, we ask the user for what to remind him/her of.

        @telegram.sendMessage
          chat_id: msg.chat.id
          text: "What to remind you of?"
          reply_to_message_id: msg.message_id

After asking so, we should grab the next input. As we only need one input, so we only grab it once. By doing so, there's no need to manually release the input. The `grabOnce` function returns also a stream waiting for the user's reply.

        .flatMap (it) -> grabOnce msg

Now that we have received what to remind the user of, we haven't known when to remind the user. So we have to ask him/her for a period of time after which we should remind him/her.

        .flatMap (it) =>
          o = @telegram.sendMessage
            chat_id: msg.chat.id
            text: "Good. Now tell me when to remind you. Please reply in this format: AhBmCsDms. e.g. 10s, 1m20s"
            reply_to_message_id: it.message_id

But we have just sent the message asking the user to provide the time, we haven't known whether the message is successfully sent. We have to wait for it, so we must use the `zip` operator to merge the two streams into one in order to wait for the `sendMessage` query to complete. We make the outputs a [text, result] array, in which the `text` is `what to remind`, and the `result` is the result of `sendMessage` query. The `result` is actually not needed, it's just here to make `RxJS` wait for the query.

          Rx.Observable.of it.text
            .zip o, (x, y) -> [x, y]

If the message is sent successfully, we can now grab the next input of the user. As we have to keep both the text to remind and the time to remind, we have to make use of the `zip` operator once again to turn the inputs into a [text, time message] array. The `time message` is the message sent by the user emitted by `grabOnce` command, which contains the time but not parsed yet.

        .flatMap (it) ->
          Rx.Observable.of it[0]
            .zip (grabOnce msg), (x, y) -> [x, y]

Now we parse the time sent by the user using the `parse-duration` module. It might throw errors, but we should not let the program crash. After this, the [text, time message] array is turned into a [text, time] array.

        .map (it) -> [it[0], parse it[1].text]
        .catch (err) -> Rx.Observable.of [err.message, 100]

Now that we have got all the information needed to complete this command. We'd better inform the user of this.

        .flatMap (it) =>
          o = @telegram.sendMessage
            chat_id: msg.chat.id
            text: "Yes, sir!"
            reply_to_message_id: msg.message_id

Again, we have to wait for the `sendMessage` query to complete. We can just omit the output emitted by `sendMessage` -- we need only the [text, time] array. Anyway, the `zip` operator will wait for both streams.

          Rx.Observable.of it
            .zip o, (x, y) -> x

For now, the stream still emits a [text, time] array after all the above operations complete. We can complete this command now. We can use the `setTimeout` function to set a callback waiting for the time set by the user, but I'd prefer keeping the streaming style. Fortunately, `RxJS` provides a `delay` operator, which can delay the emitting for a specified amount of time. By the way, we can now throw the `time` in the [text, time] array away. It is not needed any more after the `delay` operator. So we use `flatMap` operator to transform the whole stream.

        .flatMap (it) ->
          Rx.Observable.of it[0]
            .delay new Date Date.now() + it[1]

The stream is now transformed to the state in which it emits the `text` that the user sent to remind him/her of. The stream will emit it after all the operations above complete and after the set `delay`. When it emits, we can now send the text back to the user. We should also `@` the user.

        .flatMap (it) =>
          @telegram.sendMessage
            chat_id: msg.chat.id
            text: "@#{msg.from.username} #{it}"
        .subscribe null, null, ->
          console.log "Reminded @#{msg.from.username}"

Help Information
---

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
