Telegram = require './telegram'
Rx = require 'rxjs/Rx'
config = require '../config.json'
{protoKeys, parse, fromCallback} = require './utility'

commands = {}
generics = []
handlers = {}

Error.stackTraceLimit = Infinity

process.on 'uncaughtException', (err) ->
  # Do not crash the whole program
  console.warn err, err.stack.split '\n'

exports.init = ->
  tele = new Telegram

  Rx.Observable.from config.modules
    .map (m) ->
      console.log "Loading module #{m}"
      Module = require "./modules/#{m}"
      [Module, new Module tele]
    .flatMap (a) ->
      [keys, len] = protoKeys a[0].prototype
      o = Rx.Observable.of(a[1]).repeat len
      keys.zip o, (x, y) -> [x, y]
    .filter (m) -> m[0] not in ['help', 'put', 'get']
    .subscribe (m) ->
      if m[0] isnt 'generic'
        console.log "Registering command /#{m[0]}"
        commands[m[0]] = m[1]
      else
        console.log "Registering generic"
        generics.push m[1]
    , null, ->
      Help = require("./help")(commands)
      commands['help'] = new Help tele
      commands['father'] = commands['help']

      tele.getMe()
        .map (res) -> res.username
        .subscribe (name) ->
          console.log "I am #{name}"
          tele.name = name
        , (err) ->
          throw err
        , ->
          # Enter the main loop
          runForever tele

grab = (msg, callback) ->
  release msg
  handlers["#{msg.chat.id}#{msg.from.id}"] = callback
grabOnce = (msg, callback) ->
  grab msg, (m) ->
    release msg
    callback m

# Grab the input from a person in a chat to a specific handler
# Note that while the input is grabbed, generic processors will not work.
exports.grab = fromCallback grab
exports.grabOnce = fromCallback grabOnce
exports.release = release = (msg) -> handlers["#{msg.chat.id}#{msg.from.id}"] = null
exports.cleanup = cleanup = (msg) ->
  handlers["#{msg.chat.id}#{msg.from.id}"] new Error 'cancelled' if handlers["#{msg.chat.id}#{msg.from.id}"]?
  release msg

runForever = (tele) ->
  offset = 0
  run = ->
    o = tele.getUpdates offset: offset
      .flatMap (res) -> Rx.Observable.from res

    o.subscribe (u) ->
      offset = u.update_id + 1
      return if !u.message.text?
      text = u.message.text
      list = text.split ' '
      if list[0].startsWith '/'
        cmd = list[0][1...]
        index = cmd.indexOf '@'
        if index > 0
          name = cmd[(index+1)...]
          cmd = cmd[...index]
          return null if name isnt tele.getName()

        if commands[cmd]?
          try
            commands[cmd][cmd](u.message, parse(list[1...])...)
          catch error
            console.warn error
      else
        # Not a command?
        # Distribute to generic processor
        callback = handlers["#{u.message.chat.id}#{u.message.from.id}"]

        if !callback?
          for p in generics
            p.generic u.message
        else
          callback u.message
    , (err) ->
      console.warn err
    , run

  do run
