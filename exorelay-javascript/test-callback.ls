# a continuation-style method
step1 = (done) ->
  done null, 1

# another continuation-style method
step2 = (done) ->
  done null, 2


# call two continuation-style methods sequentially
workflow = (done) ->
  step1 (err, result1) ->
    | err  =>  return done err
    step2 (err, result2) ->
      | err  =>  return done err
      done null, "#{result1}, #{result2}"


workflow (err, result) ->
  console.log err, result
