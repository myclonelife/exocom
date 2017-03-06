# demonstrates wrapping a worker function that uses callbacks
# in a way that it can be called with callbacks or be yielded
require! {
  'bluebird' : {coroutine, from-callback}
  'wait' : {wait}
  'pify'
}
async = coroutine


worker = (done) ->
  wait 500, ->
    done null, 1


# can be called async or be yielded
wrapped-worker = pify worker

console.log 'starting'

# normal call with callback
wrapped-worker (err, result) ->
  console.log 'from callback:', err, result

# normal call without callback: returns promise
wrapped-worker!.then (result) -> console.log 'promise done', result

do async ->*
  result = yield wrapped-worker!
  console.log 'yield done:' result
