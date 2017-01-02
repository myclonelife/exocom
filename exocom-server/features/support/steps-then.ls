require! {
  'livescript'
  'wait' : {wait}
}


module.exports = ->

  @Then /^ExoCom broadcasts the message "([^"]*)" to the "([^"]+)" service$/, (message, service-name, done) ->
    @verify-sent-calls {service-name, message: message, id: @last-sent-message-id}, done


  @Then /^ExoCom broadcasts the reply "([^"]*)" to the "([^"]+)" service$/, (message, service-name, done) ->
    @verify-sent-calls {service-name, message: message, response-to: '111'}, done


  @Then /^ExoCom now knows about these services:$/ (table, done) ->
    services = {}
    for row in table.hashes!
      services[row.NAME] =
        name: row.NAME
        internal-namespace: row['INTERNAL NAMESPACE']
    @verify-service-setup services, done


  @Then /^ExoCom signals "([^"]*)"$/, (message, done) ->
    @verify-exocom-signaled-string message, done


  @Then /^ExoCom signals that this message was sent$/, (done) ->
    @verify-exocom-broadcasted-message message: @last-sent-message, done


  @Then /^ExoCom signals that this reply is sent from the ([^ ]+) to the (.+)$/, (sender, receiver, done) ->
    @verify-exocom-broadcasted-message message: @last-sent-message, sender: sender, receivers: [receiver], response-to: '111', done


  @Then /^ExoCom signals that this reply was sent$/, (done) ->
    @verify-exocom-broadcasted-reply @last-sent-message, done


  @Then /^ExoCom signals the error "([^"]*)"$/, (message, done) ->
    @process.wait message, done


  @Then /^it aborts with the message "([^"]*)"$/, (message, done) ->
    @verify-abort-with-message message, done


  @Then /^it has this routing table:$/, (table, done) ->
    expected-routes = {}
    for row in table.hashes!
      eval livescript.compile "receiver-json = {#{row.RECEIVERS}}", bare: yes, header: no
      expected-routes[row.MESSAGE] =
        receivers: [receiver-json]
    @verify-routing-setup expected-routes, done


  @Then /^it opens a port at (\d+)$/, (+port, done) ->
    @verify-listening-at-ports port, done


  @Then /^it opens an HTTP listener at port (\d+)$/, (+port, done) ->
    @verify-listening-at-ports port, done