exports.build = (map) ->
  Module = (telegram) ->
    @telegram = telegram
    @store = {}
    return

  for k, v of map
    Module.prototype[k] = v

  Module::put = (cid, uid, key, val) ->
    @store["#{cid}#{uid}#{key}"] = val
  Module::get = (cid, uid, key) ->
    @store["#{cid}#{uid}#{key}"]

  return Module
