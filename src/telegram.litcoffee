This is the interface of Telegram Bot API.

Here we also need to import something. `config.json` is needed for the API token.

    config = require '../config.json'
    request = require 'request'
    utility = require './utility'
    request.get = utility.fromCallback request.get, yes
    request.post = utility.fromCallback request.post, yes
    Rx = require 'rxjs/Rx'

Service
---
Build the Telegram service class

    class Telegram
      constructor: ->
        @baseURL = "https://api.telegram.org/bot#{config.token}"
        console.log "Welcome to Peter's Telegram bot"

      url: (method) -> "#{@baseURL}/#{method}"
      get: (method, options) ->
        transform request.get (@url method), form: options
      post: (method, options) ->
        transform request.post (@url method), form: options
      getName: -> @name

Telegram API methods

      getMe: -> @get 'getMe'
      getUpdates: (opt) -> @get 'getUpdates', opt
      sendMessage: (opt) -> @post 'sendMessage', opt
      sendChatAction: (opt) -> @post 'sendChatAction', opt

And we must export this service class in order to make it available.

    module.exports = Telegram

ReactiveX stream preprocessor
---
The stream is returned by the `utility.fromCallback` helper function, we have to transform it to meet our needs

    transform = (stream) ->

The first item of the stream is the `response` object, but we need only the `body`

      stream.skip 1
        .map (body) -> JSON.parse body
        .map (res) ->
          if res.ok? and res.ok
            res.result
          else
            null
