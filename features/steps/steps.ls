require! {
  'chai' : {expect}
  '../../src/observable-process' : ObservableProcess
  'path'
  'request'
}


module.exports = ->

  @Given /^a running instance of the "([^"]*)" service$/, (service-name, done) ->
    @process = new ObservableProcess("bin/exoservice-js run",
                                     cwd: path.join(process.cwd!, 'features', 'example-apps', service-name),
                                     verbose: no)
      ..wait 'online at port', done


  @Given /^I am in the "([^"]*)" service directory$/, (@service-name) ->



  @When /^executing "([^"]*)"$/, (command, done) ->
    @process = new ObservableProcess("bin/#{command}",
                                     cwd: path.join(process.cwd!, 'features', 'example-apps', @service-name),
                                     verbose: no)
      ..wait 'online at port', done


  @When /^sending a POST request to "([^"]*)"$/, (path, done) ->
    request.post url: "http://localhost:3000#{path}", (err, @response, body) ~>
      expect(err).to.be.falsy
      done!


  @When /^making a GET request to "([^"]*)"$/, (path, done) ->
    request "http://localhost:3000#{path}", (err, response, @response-body) ~>
      expect(err).to.be.falsy
      done!



  @Then /^it returns a (\d+) response$/, (expected-status) ->
    expect(@response.status-code).to.equal parse-int(expected-status, 10)


  @Then /^its console output contains "([^"]*)"$/, (output, done) ->
    @process.wait output, done


  @Then /^the service runs at port (\d+)$/, (port, done) ->
    request "http://localhost:#{port}", -> done!


  @Then /^the service shows "([^"]*)"$/, (content) ->
    expect(@response-body).to.contain content
