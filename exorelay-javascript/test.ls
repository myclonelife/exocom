require! {
  'bluebird' : {all, delay, coroutine}
}
async = coroutine


step1-co = async ->*
  console.log 'step1-co'
  yield delay 100
  1

step2-co = async (a) ->*
  console.log 'step2-co', a
  yield delay 100
  2


console.log 'starting'

console.log step1-co!


workflow-co-sequential = async ->*
  result1 = yield step1-co!
  result2 = yield step2-co 'abc'
  "#{result1}, #{result2}"
  yeild return

# workflow-co-sequential!.then (result) -> console.log 'co-sequential done:' result
#                        .catch (err) -> console.log 'boom', err


workflow-co-parallel = async ->*
  [result1, result2] = yield all [step1-co!, step2-co('text')]
  "#{result1}, #{result2}"


do async ->*
  result = yield workflow-co-parallel!
  console.log 'co-parallel done:' result
