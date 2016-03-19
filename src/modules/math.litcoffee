The `math` module acts like a convenient and powerful calculator in Telegram chats. This makes use of the npm module `math.js` to provide powerful math functionalities.

    Rx = require 'rxjs/Rx'
    Module = require '../module'
    math = require 'mathjs'
    {check} = require '../utility'

    module.exports = class Math extends Module

Calc
---
This is the main function of this module. It takes unlimited arguments. The arguments, as a whole, will be splitted into lines and evaluated line by line. See the `math.js` homepage <http://mathjs.org/> for detailed information.

      calc: (msg, args...) ->
        str = args.join ' '

        res = ''

`math.js` has some problems directly executing long expressions. As a workaround, we split them into lines and use `parser` to execute them. No worry, things like temporary variables will be kept cross lines.

        parser = math.parser()

        Rx.Observable.from str.split '\n'
          .map (it) -> parser.eval it

Omit empty and error outputs.

          .filter (it) -> it isnt ''
          .catch (err) -> Rx.Observable.of err.message

Build the output on a line-to-line basis, which means each line of input produces a line of non-empty output. Here, the stream still emits the result lines one-by-one. We will need to put them into an array and re-join them into one stream line by line.

          .toArray()
          .map (it) -> it.join '\n'
          .flatMap (it) =>
            @telegram.sendMessage
              chat_id: msg.chat.id
              text: it
              reply_to_message_id: msg.message_id
          .subscribe null, (err) ->
            console.warn err

Help information
---

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
