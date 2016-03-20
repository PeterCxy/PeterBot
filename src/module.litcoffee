    path = require 'path'
    fs = require 'fs'

Base class of all modules.

    module.exports = class Module
      constructor: (@telegram) ->
        @store = {}
        @save = false unless @save?

Restore data

        if @save
          @file = path.resolve __dirname, "../data/#{@constructor.name}"
          console.log "Loading data from file #{@file}"
          @store = try
            JSON.parse fs.readFileSync @file
          catch err
            {}


The following methods are convenient functions to temporarily store some info for a user in a chat. These two should be excluded from the commands list.

      put: (cid, uid, key, val) ->
        @store["#{cid}#{uid}#{key}"] = val

        if @save
          fs.writeFile @file, (JSON.stringify @store), (err) =>
            throw err if err?

      get: (cid, uid, key) ->
        @store["#{cid}#{uid}#{key}"]
