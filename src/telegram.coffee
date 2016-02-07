config = require '../config.json'
rest = require 'restler'
Rx = require 'rxjs/Rx'

Telegram = rest.service ->
  console.log "Welcome to Peter's Telegram bot"
, baseURL: "https://api.telegram.org/bot#{config.token}",
  getMe: -> observe @get '/getMe'
  getName: -> @name
  getUpdates: (options) -> observe @get '/getUpdates', data: options
  sendMessage: (options) -> observe @post '/sendMessage', data: options

# The original implementation uses url.resolve to compose the url
# Which will cut the bot token off from the entire url
# So we just replace it.
Telegram::_url = (path) ->
  "#{@baseURL}#{path}"

module.exports = Telegram

# Convert to Observable
observe = (o) ->
  Rx.Observable.create (observer) ->
    o.on 'complete', (res) ->
      if !res? or (res instanceof Error)
        observer.error res
      else
        if res.ok? && res.ok
          observer.next res.result
        else
          observer.error new Error res.description
      observer.complete()
