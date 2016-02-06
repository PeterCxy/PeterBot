exports.build = (map) ->
  Module = (telegram) ->
    @telegram = telegram
    return

  for k, v of map
    Module.prototype[k] = v

  return Module
