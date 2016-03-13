This is the interface of Telegram Bot API implemented with the `restler` npm module.

Here we also need to import something. `config.json` is needed for the API token.

    config = require '../config.json'
    rest = require 'restler'
    Rx = require 'rxjs/Rx'

Service
---
The `restler` module provides a helper function `service` to quickly create a REST API interface with the API URL and method names.

    Telegram = rest.service ->
      console.log "Welcome to Peter's Telegram bot"
    , baseURL: "https://api.telegram.org/bot#{config.token}",
      getMe: -> observe @get '/getMe'
      getName: -> @name
      getUpdates: (options) -> observe @get '/getUpdates', data: options
      sendMessage: (options) -> observe @post '/sendMessage', data: options
      sendChatAction: (options) -> observe @post '/sendChatAction', data: options

However, in the original implementation of `restler`, the URL is resolved using `url.resolve`, which omits all the paths in the `baseURL` and keeps only the host name. This won't work for us, as Telegram API's token is specified in the URL. We must replace the method `_url` which resolves the url and replace it. We just append the method path to the base url.

    Telegram::_url = (path) ->
      "#{@baseURL}#{path}"

And we must export this service class in order to make it available.

    module.exports = Telegram

ReactiveX-ify
---
I wrote this bot with the style of ReactiveX (RxJS). However, the `restler` module does not support RxJS, which means I must convert it to `Rx.Observable` manually. So I created a helper function. It consumes an object returned by the `restler` module, and returns an `Observable` which emits the result when the `restler` object emits `complete` event.

    observe = (o) ->
      Rx.Observable.create (observer) ->
        o.on 'complete', (res) ->

A `loop` keyword is used here. This is actually not a loop. But if we use the `loop` keyword here, we can break from any point of the code inside the `loop` keyword. This makes much sense when we need to do error processing.

          loop
            if !res? or (res instanceof Error)

We have to prevent the bot from crashing.

              try
                observer.error res
              catch e
                console.log e
                break
            else
              if res.ok? && res.ok
                observer.next res.result
              else
                try
                  observer.error new Error res.description
                catch e
                  console.log e
                  break
            observer.complete()
            break
