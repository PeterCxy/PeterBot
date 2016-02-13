Rx = require 'rxjs/Rx'
math = require 'mathjs'
{check} = require '../utility'

module.exports = require('../builder').build
  calc: (msg, args...) ->
    str = args.join ' '

    res = ''
    parser = math.parser()

    Rx.Observable.from str.split '\n'
      .map (it) -> parser.eval it
      .filter (it) -> it isnt ''
      .catch (err) -> Rx.Observable.of err.message
      .toArray()
      .map (it) -> it.join '\n'
      .flatMap (it) =>
        @telegram.sendMessage
          chat_id: msg.chat.id
          text: it
          reply_to_message_id: msg.message_id
      .subscribe null, (err) ->
        console.warn err

  help:
    calc: '''
/calc expression
Calulate one or multiple __math.js__ expressions.
Split multiple expressions in one line with ';'.
Note that expressions ending with ';' will not produce any outout.
e.g.
```
  x = 1; y = 2; x + y
```
will produce `[3]` as the output.
e.g.
```
  x = 1; y = 2; x + y
  x * y
```
will produce an output like
```
  [3]
  2
```
see [math.js](http://mathjs.org) for details
'''
