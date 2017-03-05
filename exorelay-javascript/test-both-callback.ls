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


# can be called async or for promise
wrapped-worker = (done) ->
  | done  =>  worker done
  | _     =>  from-callback worker


console.log 'starting'

wrapped-worker (err, result) ->
  console.log 'from callback:', err, result

do async ->*
  result = yield wrapped-worker!
  console.log 'yield done:' result
