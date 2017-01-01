require! 'co'


step1-co = co ->*
  console.log 'step1-co'romise.resolve 1

step2-co = co ->*
  console.log 'step2-co'
  yield Promise.delay 1000
  'hello'


console.log 'starting'



actual-function = (done) ->
  setTimeout ->
    done null, 1


wrapped = (done) ->
  | done => actual-function done
  | _    => Promise.from-node actual-function


# usable via either callbacks or promises
workflow-both-co = co.wrap (done) ->*
  | done  =>  done null, 1
  | _     =>  yield Promise.resolve 1


workflow-both-co!.then (result) -> console.log 'promise returns:' result
                 .catch (err) -> console.log 'boom', err

workflow-both-co (err, result) ->
  console.log 'callback returns:' err, result
