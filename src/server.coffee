Telegram = require './telegram'
config = require '../config.json'
{check} = require './utility'

commands = {}

exports.init = ->
  tele = new Telegram

  for m in config.modules
    console.log "Loading module #{m} ..."
    Module = require "./modules/#{m}"

    instance = new Module tele

    for k of Module.prototype
      continue if k is 'help'
      console.log "Command /#{k} has a implementation in #{m}"
      commands[k] = instance

  Help = require("./help")(commands)
  commands['help'] = new Help tele

  tele.getMe().on 'complete', check (res) ->
    console.log "I am #{res.username}"
    tele.name = res.username
    runForever tele

runForever = (tele) ->
  offset = 0
  run = ->
    tele.getUpdates(offset: offset).on 'complete', check (res) ->
      for u in res
        offset = u.update_id + 1
        text = u.message.text
        list = text.split ' '
        if list[0].startsWith '/'
          cmd = list[0][1...]
          index = cmd.indexOf '@'
          if index > 0
            name = cmd[(index+1)...]
            cmd = cmd[...index]
            continue if name isnt tele.getName()

          if commands[cmd]?
            try
              commands[cmd][cmd](u.message, list[1...]...)
            catch error
              console.warn error
      do run
  do run
