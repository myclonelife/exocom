# demonstrates wrapping a worker function that uses callbacks
# in a way that it can be called with callbacks or be yielded
require! {
  'bluebird' : {coroutine, from-callback}
  'wait' : {wait}
}
async = coroutine


worker = (done) ->
  wait 500, ->
    done null, 1


# Makes the given callback-based worker function accessible as a generator and as a callback
combo-api-for-callback = (worker) ->
  (done) ->
    | done  =>  worker done
    | _     =>  from-callback worker



# can be called async or be yielded
wrapped-worker = combo-api-for-callback worker

console.log 'starting'

# normal call with callback
wrapped-worker (err, result) ->
  console.log 'from callback:', err, result

# normal call without callback: returns promise
wrapped-worker!.then (result) -> console.log 'promise done', result

do async ->*
  result = yield wrapped-worker!
  console.log 'yield done:' result
