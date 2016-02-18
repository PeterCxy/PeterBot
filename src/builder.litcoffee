This is a helper function to build module classes for this bot. It consumes a `map` object which is a {name: function} map. It's just like the `restler.service` function, in which it converts every {key: value} pair in the map to a property of the class.

    exports.build = (map) ->

The constructor accepts the `telegram` service object.

      Module = (telegram) ->
        @telegram = telegram
        @store = {}
        return

Convert each {key: value} pair to prototype.

      for k, v of map
        Module.prototype[k] = v

The following methods are convenient functions to temporarily store some info for a user in a chat. These two should be excluded from the commands list.

      Module::put = (cid, uid, key, val) ->
        @store["#{cid}#{uid}#{key}"] = val
      Module::get = (cid, uid, key) ->
        @store["#{cid}#{uid}#{key}"]

      return Module
