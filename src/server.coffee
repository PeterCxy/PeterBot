Telegram = require './telegram'
Rx = require 'rxjs/Rx'
config = require '../config.json'
{check} = require './utility'

commands = {}
generics = []

exports.init = ->
  tele = new Telegram

  for m in config.modules
    console.log "Loading module #{m} ..."
    Module = require "./modules/#{m}"

    instance = new Module tele

    for k of Module.prototype
      continue if k is 'help'

      if k isnt 'generic'
        console.log "Command /#{k} has a implementation in #{m}"
        commands[k] = instance
      else
        console.log "Registered generic message processor from #{m}"
        generics.push instance

  Help = require("./help")(commands)
  commands['help'] = new Help tele
  commands['father'] = commands['help']

  tele.getMe()
    .map (res) -> res.username
    .subscribe (name) ->
      console.log "I am #{name}"
      tele.name = name
      runForever tele
    , (err) ->
      throw err

runForever = (tele) ->
  offset = 0
  run = ->
    o = tele.getUpdates offset: offset
      .flatMap (res) -> Rx.Observable.from res

    o.subscribe (u) ->
      offset = u.update_id + 1
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
            commands[cmd][cmd](u.message, list[1...]...)
          catch error
            console.warn error
      else
        # Not a command?
        # Distribute to generic processor
        for p in generics
          p.generic u.message
    , (err) ->
      console.warn err
    , run

  do run
