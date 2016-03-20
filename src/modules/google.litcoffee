A simple Google search module
This module depends on the `googler-coffee` module

    Rx = require 'rxjs/Rx'
    Module = require '../module'
    googler = require '../utility'
      .fromCallback require('googler-coffee').google, yes
    module.exports = class Google extends Module
      constructor: ->
        @save = true
        super

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

Now that we have got everything needed. We can start the search now.
We prefer English results. And the auto-correction is never needed.

Each time, we only fetch one result. Do not send long messages!

        @telegram.sendChatAction
          chat_id: msg.chat.id
          action: 'typing'
        .flatMap ->
          googler
            query: query
            start: start
            num: 1
            lang: 'en'
            exact: yes
            tld: 'co.uk'
        .map (it) ->
          if it.length > 0
            it[0]
          else
            "('・ω・') Nothing could be found"
        .map (it) ->
          if it.title?
            "#{it.title}\n#{it.url}\n\n#{it.content}"
          else
            it
        .flatMap (it) =>
          @telegram.sendMessage
            chat_id: msg.chat.id
            text: it
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
