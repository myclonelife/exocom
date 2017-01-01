step1-cb = (done) ->
  done null, 1

step2-cb = (done) ->
  done null, 2


workflow-cb = (done) ->
  step1-cb (err, result1) ->
    | err  =>  return done err
    step2-cb (err, result2) ->
      | err  =>  return done err
      done null, "#{result1}, #{result2}"


workflow-cb (err, result) ->
  console.log err, result
