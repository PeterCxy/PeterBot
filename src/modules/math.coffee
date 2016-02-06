math = require 'mathjs'
{check, args} = require '../utility'

module.exports = require('../builder').build
  calc: (msg) ->
    str = args(arguments)[1...].join ' '

    res = ''
    parser = math.parser()
    for line in str.split '\n'
      t = parser.eval line
      res += t + '\n' if t isnt ''

    @telegram.sendMessage
      chat_id: msg.chat.id
      text: res
      reply_to_message_id: msg.message_id
    .on 'complete', check ->
      console.log "Evaluated #{str}"

  help:
    calc: '''
/calc expression
Calulate one or multiple **math.js** expressions.
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
