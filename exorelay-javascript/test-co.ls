require! {
  'bluebird' : {all, delay, coroutine}
}
async = coroutine


# a generator function, returns 1 after 100ms
step1 = async ->*
  console.log 'step1 is running'
  a = delay 1000
  console.log a
  yield a
  1


# another generator function, returns 2 after 100ms
step2 = async (a) ->*
  console.log 'step2 is running with argument', a
  yield delay 1000
  2


console.log 'starting'


# call the two methods above sequentially
workflow-sequential = async ->*
  result1 = yield step1!
  result2 = yield step2 'abc'
  "#{result1}, #{result2}"

# workflow-co-sequential!.then (result) -> console.log 'co-sequential done:' result
#                        .catch (err) -> console.log 'boom', err


# call the two methods above in parallel
workflow-parallel = async ->*
  [result1, result2] = yield all [step1!, step2 'text']
  "#{result1}, #{result2}"



do async ->*
  result = yield workflow-sequential!
  console.log 'done:' result
