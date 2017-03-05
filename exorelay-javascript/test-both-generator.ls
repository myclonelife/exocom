# demonstrates wrapping a worker function implemented as a generator
# in a way that it can be called with callbacks or be yielded
require! {
  'bluebird' : {coroutine, delay}
}
async = coroutine


worker = async ->*
  yield delay 1000
  1


# Makes the given generator worker function accessible as a generator and as a callback
combo-api-for-generator = (worker) ->
  async (done) ->*
    result = yield worker!
    if done
      done null, result
    result


# usable via either callbacks or by yielded
wrapped-worker = combo-api-for-generator worker


console.log 'starting'

# normal call with callback
wrapped-worker (err, result) ->
  console.log 'callback done', err, result


# normal call without callback: returns promise
wrapped-worker!.then (result) -> console.log 'promise done', result

# call via yield
do async ->*
  result = yield wrapped-worker!
  console.log 'yield done:' result
