This is the main entry of Peter's Telegram bot. We have to import some things first.

    Telegram = require './telegram'
    Rx = require 'rxjs/Rx'
    config = require '../config.json'
    {protoKeys, parse, fromCallback} = require './utility'

Global variables
---
Available commands will be stored here.
Messages that start with `/` will be treated as commands, and a corresponding callback will be fired if registered here.

    commands = {}

`generics` are called whenever a non-command message is received.

    generics = []

`handlers` are callbacks waiting for inputs. They are usually registered by a previously-called command that needs more input.

    handlers = {}

As we make use of RxJS, we should remove the limit on stack traces, or it will be hard to debug.

    Error.stackTraceLimit = Infinity

Let's make the error output more readable.

    process.on 'uncaughtException', (err) ->
      console.error err, err.stack.split '\n'

Entry
---

Here we come to the entry of the whole program. It's called by `index.js`

    exports.init = ->
      tele = new Telegram

Now we are about to load all the modules into memory.
A module is a class that provides a set of commands or a generic processor of messages. For now, only modules located in `src/modules` can be loaded. To make the program load a module, add it to the `modules` array in `config.json`

      Rx.Observable.from config.modules
        .map (m) ->

For every module, we load it into memory with `require`

          console.log "Loading module #{m}"
          Module = require "./modules/#{m}"
          [Module, new Module tele]
        .flatMap (a) ->

Get all properties of every module. The properties' names will be used as names of callable commands.

          [keys, len] = protoKeys a[0].prototype
          o = Rx.Observable.of(a[1]).repeat len

The `zip` operator is employed to make a [command, module] array for the convenience of registering commands.

          keys.zip o, (x, y) -> [x, y]

There are some preserved properties.
`help` is used by the `/help` command to store the help information.
`put` and `get` are temporary storage methods.

        .filter (m) -> m[0] not in ['help', 'put', 'get']
        .subscribe (m) ->

If the property's name is not `generic`, it is just a normal command. We add it to the `commands` map, which is a {name: module} map.

          if m[0] isnt 'generic'
            console.log "Registering command /#{m[0]}"
            commands[m[0]] = m[1]

Or, it is a generic processor of messages. We push it into the `generics` array.

          else
            console.log "Registering generic"
            generics.push m[1]
        , null, ->

However, there is a special module called `help`. It is the module that manages the help information of all the loaded modules. It is so special that it is even not located inside the `modules` directory. This module needs to be loaded manually.

          Help = require("./help")(commands)
          commands['help'] = new Help tele
          commands['father'] = commands['help']

Now that we have done all the dirty dirty works before the bot starts. But wait, we do not even know the bot's name! So let's get it before everything begin.

          tele.getMe()
            .map (res) -> res.username
            .subscribe (name) ->
              console.log "I am #{name}"
              tele.name = name
            , (err) ->
              throw err
            , ->

Now we get into the main loop! Hurray!

              runForever tele

Message Handlers
---
Sometimes, when a command is called, it has not get all the information needed for it to run. If so, the module that the command belongs to will be in need of further information sent by the user. In this case, the module will need to register a callback into this main module and then wait for further input.

To register a callback that grabs all future inputs without limits,

    grab = (msg, callback) ->
      release msg

It is necessary to record the sender's id and the chat in which the handler works. Otherwise we will mess everything up.

      handlers["#{msg.chat.id}#{msg.from.id}"] = callback

To grab only the next input,

    grabOnce = (msg, callback) ->
      grab msg, (m) ->

Just register a callback that unregisters itself once fired.

        release msg
        callback m

However, remember that this bot is mainly in the style of ReactiveX, which means callbacks are not the best solution. So we have to export these functions as Rx Observables. See the `utility` module for more details on converting callbacks to Rx Observables.

    exports.grab = fromCallback grab
    exports.grabOnce = fromCallback grabOnce

Handlers cannot work forever. They need a way to unregister themselves. To unregister a handler for the sender in the chat group of a message,

    exports.release = release = (msg) -> handlers["#{msg.chat.id}#{msg.from.id}"] = null

Sometimes, handlers need to be informed of themselves' cancellation.

    exports.cleanup = cleanup = (msg) ->
      handlers["#{msg.chat.id}#{msg.from.id}"] new Error 'cancelled' if handlers["#{msg.chat.id}#{msg.from.id}"]?
      release msg

Main Loop
---
As is known to us, this bot works only in the mode of long-polling, so a main loop is needed.

    runForever = (tele) ->

We do not use the `loop` keyword. Instead, a function is called by itself which is called by itself...
Don't worry, we won't get into any overflows.

      offset = 0
      run = ->

Each time, we need to poll the Telegram server for available updates on the bot's received messages. We set the timeout to 10 minutes as a long-poll.

        o = tele.getUpdates
              offset: offset
              timeout: 600

The result stream emits an array, but we do not need the array itself. So we unfold it into a stream.

          .flatMap (res) -> Rx.Observable.from res

        o.subscribe (u) ->

For every update, we record its `id + 1` as the offset. By doing so, we will get an `offset` pointing to the next possible update every time a query finishes.

          offset = u.update_id + 1

At this moment, this bot has not implemented support for empty messages such as stickers. So they are just ignored.

          return if !u.message.text?

Do some pre-processing jobs.

          text = u.message.text

By default, a command's arguments are seperated with spaces, so we split the text by a space.

          list = text.split ' '

According to the Telegram rules, messages starting with `/` are considered commands of bots.
But in super groups, bots may not receive commands that are not tagged with bot's name. So we use an alternative prefix `!`.

          if (list[0].startsWith '/') or (list[0].startsWith '!')
            cmd = list[0][1...]

In some cases, multiple bots will consume commands of the same name. If so, conflicts are possible. So a command may point out the bot that is responsible to consume this command. e.g. `/help@PeterCxyBot`

            index = cmd.indexOf '@'
            if index > 0
              name = cmd[(index+1)...]
              cmd = cmd[...index]

If the name in such a command does not correspond to the bot's name, we will just omit this message.
Note that in super groups, only such commands can be received by the bot.

              return null if name isnt tele.getName()

If this command exists in the `commands` array, we will send it to the corresponding module.
However, there is one more thing to do. As is mentioned, arguments are seperated with spaces. But what if an argument contains spaces? The solution is to wrap it with single-quotes `'`. To do so, we need a function to parse such arguments. It is implemented in the `utility` module.
And we might not want to crash the whole program if a command errors.

            if commands[cmd]?
              try
                commands[cmd][cmd](u.message, parse(list[1...])...)
              catch error
                console.warn error

If a message do not start with `/`, it means that this message is just a normal message. We will send it to generic processors or handlers if any.
In groups, bots without special permission will not receive such messages. They can only recive commands and messages that reply to the bot's message. For further information on such privacy permission, consult `@BotFather` for details.

          else
            callback = handlers["#{u.message.chat.id}#{u.message.from.id}"]

            if !callback?
              for p in generics
                p.generic u.message
            else
              callback u.message

Errors? Log them.

        , (err) ->
          console.warn err

Just start this function again on success.

        , run

And here is where everything begins.

      do run
