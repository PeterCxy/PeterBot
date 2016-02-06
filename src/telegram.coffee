config = require '../config.json'
rest = require 'restler'

Telegram = rest.service ->
  console.log "Welcome to Peter's Telegram bot"
, baseURL: "https://api.telegram.org/bot#{config.token}",
  getMe: -> @get '/getMe'
  getName: -> @name
  getUpdates: (options) -> @get '/getUpdates', data: options
  sendMessage: (options) -> @post '/sendMessage', data: options

# The original implementation uses url.resolve to compose the url
# Which will cut the bot token off from the entire url
# So we just replace it.
Telegram::_url = (path) ->
  "#{@baseURL}#{path}"

module.exports = Telegram
