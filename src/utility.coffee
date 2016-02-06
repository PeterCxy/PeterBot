exports.check = (callback) ->
  (res) ->
    console.warn res if res instanceof Error
    console.warn res.description if !res.ok
    callback res.result

# Convert arguments to Array
exports.args = (argument) ->
  Array::slice.call argument
