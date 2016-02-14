Rx = require 'rxjs/Rx'

exports.check = (callback) ->
  (res) ->
    console.warn res if res instanceof Error
    console.warn res.description if !res.ok
    callback res.result

# Convert arguments to Array
exports.args = args = (argument) ->
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
exports.fromCallback = (func) ->
  ->
    a = args arguments
    Rx.Observable.create (observer) ->
      a.push ->
        observer.next (args arguments)...
        observer.complete()
      try
        func a...
      catch err
        observer.error err

# Arguments parser
exports.parse = (args) ->
  ret = []
  arr = []
  Rx.Observable.from args
    .flatMap (i) ->
      if i.startsWith("'") and arr.length is 0
        arr.push i[1..]
        Rx.Observable.from []
      else if i[i.length - 1] is "'" and arr.length > 0
        arr.push i[..-2]
        str = arr.join ' '
        arr = []
        Rx.Observable.of str
      else if arr.length > 0
        arr.push i
        Rx.Observable.from []
      else
        Rx.Observable.of i
    .toArray()
    .subscribe (i) ->
      ret = i

  # All the above operations are synchronous
  # So we can just return something here
  ret
