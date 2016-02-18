Blackgun is `黑枪` in Chinese. It refers to something irony but not that irony -- more like kidding. Just for fun.

## All the following content are only made for fun. DO NOT TAKE THEM SERIOUS.

    Rx = require 'rxjs/Rx'

Main
---
The module is registered as a generic processor. It receive everything and detects if `Blackgun` is needed.

    module.exports = require('../builder').build
      generic: (msg) ->

Go through the conditions defined below, and try each condition on this message. If the condition function returns not `undefined` or returns true, it means that this `blackgun` is available for this message. We store the corresponding action temporarily.

        Rx.Observable.from guns
          .map (it) -> [(it.cond msg), it.act]
          .filter (it) -> it[0]? and it[0]

We do not do more than once for one message.

          .take 1

Apply the corresponding `action` if `blackgun` available. The value returned by the condition function is passed to the action function, which may need it. After this, send it to the original chat.

          .flatMap (it) =>
            @telegram.sendMessage
              chat_id: msg.chat.id
              text: it[1](it[0], msg)
              reply_to_message_id: msg.message_id
          .subscribe null, (err) ->
            console.log "Gun failed to activate to #{msg.from.username}: #{err}"

Conditions
---
The following code defines a set of conditions and the corresponding action to `blackgun` with it. The `cond` function of each condition should return true or a non-null value if the message satisfies the condition. The return value will be passed to the `act` function in order to apply the corresponding action.

    guns = [

##### Rich or Poor?

There is always some `#RICH` people calling themselves `#POOR` and vice-versa. So --

        cond: (msg) -> msg.text.match /#RICH/gi
        act: -> '#POOR'
      ,
        cond: (msg) -> msg.text.match /#POOR/gi
        act: -> '#RICH'
      ,


##### Moons with faces

The two emojis `Full moon with face` and `New moon with face` are often used to describe luckiness and unluckiness. This is fun! So we can do something like this --

        cond: (msg) -> (msg.text.match /\uD83C\uDF1A|\uD83C\uDF1D/g)?.filterLessThan 2

We only do this type of `blackgun` when there are more than 1 moon faces in the message text. Now we have extracted all the moon faces in the string. If any, we will replace the `full moon` with `new moon` and vice-versa as the action to do `blackgun` with the message. Note that we must employ a temporary placeholder in order to do this!

        act: (cond) ->
          cond.join ''
              .replace /\uD83C\uDF1D/g, 'temp'
              .replace /\uD83C\uDF1A/g, '\uD83C\uDF1D'
              .replace /temp/g, '\uD83C\uDF1A'


##### The end

# Again: DO NOT TAKE THEM SERIOUS.

    ]
