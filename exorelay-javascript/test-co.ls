require! {
  'bluebird' : {all, delay, coroutine}
}
async = coroutine


# a generator function, returns 1 after 100ms
step1-co = async ->*
  console.log 'step1-co'
  yield delay 100
  1

# another generator function, returns 2 after 100ms
step2-co = async (a) ->*
  console.log 'step2-co', a
  yield delay 100
  2


console.log 'starting'

console.log step1-co!


# call the two methods above sequentially
workflow-co-sequential = async ->*
  result1 = yield step1-co!
  result2 = yield step2-co 'abc'
  "#{result1}, #{result2}"
  yield return

# workflow-co-sequential!.then (result) -> console.log 'co-sequential done:' result
#                        .catch (err) -> console.log 'boom', err


# call the two methods above in parallel
workflow-co-parallel = async ->*
  [result1, result2] = yield all [step1-co!, step2-co('text')]
  "#{result1}, #{result2}"



do async ->*
  result = yield workflow-co-parallel!
  console.log 'co-parallel done:' result
