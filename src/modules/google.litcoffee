A simple Google search module

    {exec} = require 'child_process'

This module depends on the `googler` script.
Please download it from <https://github.com/jarun/googler>,
and point the `googler` field in `config.json` to it.

    {googler} = require '../../config.json'
    module.exports = require('../builder').build

Google
---

      google: (msg, args...) ->
        query = args?.join ' '

When called with no arguments, we try to continue the last query.

        start = 0

        if !query? or query.trim() is ''
          query = @get msg.chat.id, msg.from.id, 'query'
          start = @get msg.chat.id, msg.from.id, 'start'
          start += 1 if query?

        if !query? or query.trim() is ''
          @telegram.sendMessage
            chat_id: msg.chat.id
            text: "(；一_一) I don't know what to search for"
            reply_to_message_id: msg.message_id
          .subscribe null, (err) ->
            console.log err
          return

        @put msg.chat.id, msg.from.id, 'query', query
        @put msg.chat.id, msg.from.id, 'start', start

Now that we have got everything needed. We can spawn `googler` and do the search.
`googler` cannot work correctly when Google automatically redirects to contry-specific domains.
So let's specify an English-speaking country.

We do not need autocorrection either. The `-x` turns it off.

        exec "#{googler} -C -x -c uk -n 1 -s #{start} #{query} < /dev/null", (err, stdout) =>
          throw err if err?

There is always a trailing line. We just replace it with nothing.

          res = stdout.replace 'Enter n, p, result number or new keywords:', ''
          res = "('・ω・') Nothing could be found." if res.trim() is ''

We can now send the result back to the user.

          @telegram.sendChatAction
            chat_id: msg.chat.id
            action: 'typing'
          .flatMap (it) =>
            @telegram.sendMessage
              chat_id: msg.chat.id
              text: res
              reply_to_message_id: msg.message_id
          .subscribe null, (err) ->
            console.log err

Help
---

      help:
        google: '''
    /google query
    Google for `query`.
    If `query` not provided, the last query will be continued.
    '''
