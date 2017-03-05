# demonstrates wrapping a worker function implemented as a generator
# in a way that it can be called with callbacks or be yielded
require! {
  'bluebird' : {coroutine, delay}
}
async = coroutine


worker = async ->*
  yield delay 1000
  1


# usable via either callbacks or by yielded
wrapped-worker = async (done) ->*
  result = yield worker!
  if done
    done null, result
  result


# call via callback
wrapped-worker (err, result) ->
  console.log 'callback done', err, result


# call via yield
do async ->*
  result = yield wrapped-worker!
  console.log 'yield done:' result
