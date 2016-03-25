Here we come to the unified helper module of the bot. This module provides some convenient methods or functions for the bot.

We have to import RxJS first.

    Rx = require 'rxjs/Rx'

This function converts the `arguments` object to Array.

    exports.args = args = (argument) ->
      Array::slice.call argument

Strings
---

`String.contains` method detects whether a string contains a subsequence.

    String::contains = (str) -> this.indexOf(str) >= 0

`String.repeat` repeats a sequence for a specified amount.

    String::repeat = (n) -> Array(n + 1).join this

Arrays
---

`Array.filterLessThan` returns null if an array's length is lesser than a specified number, returns the array itself otherwise.

    Array::filterLessThan = (num) -> if @length >= num then this else null

ReactiveX
---
The following functions are for `RxJS`

`protoKeys` converts all property names of a Class to an Rx stream.

    exports.protoKeys = (type) ->
      keys = Object.getOwnPropertyNames type
      o = Rx.Observable.from keys
        .filter (k) -> k isnt 'constructor'

It returns the length of the keys too.

      [o, keys.length]

We sometimes need to convert a node-style callback method to an Rx style streaming method. This dirty work is done here.

    exports.fromCallback = (func, errFirst) ->
      errFirst = false if !errFirst?

Let's return a new function, in which we will register a callback wrapper and call the original function.

      ->

We need to save the list of arguments in this outer function, or we won't be able to access it.

        a = args arguments
        Rx.Observable.create (observer) ->

Node-style callbacks are always the last argument of the function. So, we just append a callback wrapper to the arguments list.

          a.push ->

Cancel if we have received a `cancel` event.

            if arguments[0] instanceof Error and arguments[0].message is 'cancelled'
              console.log 'Cancel event received.'
              throw arguments[0]

If the first argument should be an error.

            if errFirst
              if arguments[0]?
                observer.error arguments[0]
              else
                (args arguments)[1...].map (it) -> observer.next it

Otherwise, we emit the result.

            else
              (args arguments).map (it) -> observer.next it

            observer.complete()

Now we have created the callback wrapper. We can now call the original function with the arguments and the callback wrapper.

          try
            func a...
          catch err
            observer.error err

In this way, a new function is created and returned. It will just behave like a streaming function.

Arguments parser
---
As is described in the `server` module, when an argument of a command contains spaces, it needs to be wrapped up with `'`. The following function parses such arguemnts and merge the wrapped arguemnts into one.

    exports.parse = (args) ->
      ret = []

The `arr` array is a temporary storage where a list of arguments wrapped with `'` is stored.

      arr = []
      Rx.Observable.from args
        .flatMap (i) ->

If the temporary storage is empty and this argument starts with `'`, it must be the start of an argument which contains spaces.

          if i.startsWith("'") and arr.length is 0
            arr.push i[1..]

If so, we will omit this arguemnt itself. We wait until the end of the argument.

            Rx.Observable.from []

If this argument ends with `'` and the storage is not empty, it must be the end of an arguemnt which contains spaces. In this case, we rebuild the arguemnt from the temporary storage, add them as one arguemnt to the result list, and then clear the storage.

          else if i[i.length - 1] is "'" and arr.length > 0
            arr.push i[..-2]
            str = arr.join ' '
            arr = []
            Rx.Observable.of str

If the storage is not empty and there's no special marks in this arguemnt, it must be in the body of an argument which contains spaces. We push it to the storage and wait for the end.

          else if arr.length > 0
            arr.push i
            Rx.Observable.from []

Otherwise, it is just a normal arguement.

          else
            Rx.Observable.of i

Some arguments might be empty. We filter them out - no empty arguments are allowed!

        .filter (it) -> it?.trim() isnt ''

Now we just wait for the operations to complete.

        .toArray()
        .subscribe (i) ->
          ret = i

As all the above operations are done synchronously, this function won't return until all the work completes even if it makes use of RxJS's streaming support. So we can just return the result as usual. It won't need any callbacks or streaming.

      ret
