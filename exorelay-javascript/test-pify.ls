# demonstrates wrapping a worker function that uses callbacks
# in a way that it can be called with callbacks or be yielded
require! {
  'bluebird' : {coroutine, from-callback}
  'wait' : {wait}
  'pify'
}
async = coroutine


worker = (number, done) ->
  console.log number
  wait 500, ->
    done null, number


# can be called async or be yielded
wrapped-worker = pify worker

console.log 'starting'

# normal call with callback
wrapped-worker 1, (err, result) ->
  console.log 'from callback:', err, result

# normal call without callback: returns promise
wrapped-worker(2).then (result) -> console.log 'promise done', result

do async ->*
  result = yield wrapped-worker 3
  console.log 'yield done:' result
