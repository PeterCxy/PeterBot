Rx = require 'rxjs/Rx'

exports.check = (callback) ->
  (res) ->
    console.warn res if res instanceof Error
    console.warn res.description if !res.ok
    callback res.result

# Convert arguments to Array
exports.args = (argument) ->
  Array::slice.call argument

# Strings
String::contains = (str) -> this.indexOf(str) >= 0
String::repeat = (n) -> Array(n + 1).join this

# Rx utils
exports.protoKeys = (type) ->
  keys = Object.getOwnPropertyNames type
  o = Rx.Observable.from keys
    .filter (k) -> k isnt 'constructor'
  [o, keys.length]
