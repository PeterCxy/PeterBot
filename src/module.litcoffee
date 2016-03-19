Base class of all modules.

    module.exports = class Module
      constructor: (@telegram) ->
        @store = {}

The following methods are convenient functions to temporarily store some info for a user in a chat. These two should be excluded from the commands list.

      put: (cid, uid, key, val) ->
        @store["#{cid}#{uid}#{key}"] = val
      get: (cid, uid, key) ->
        @store["#{cid}#{uid}#{key}"]
