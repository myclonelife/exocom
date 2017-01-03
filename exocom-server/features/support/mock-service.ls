require! {
  'ws' : WebSocket
}
debug = require('debug')('mock-service')


# A class to encapsulate the functionality of a service in the ExoSphere
# that can send, receive, and track messages using WebSockets.
class MockService

  ({@port, @name, @namespace} = {}) ->

    # list of messages that this mock service has received from Exocom
    @received-messages = []

    # the last message sent to Exocom
    @last-sent-message = null


  close: ~>
    | @closed => return
    @socket?.close!
    @closed = yes


  connect: ({message-name, payload}, done) ~>
    payload ?= {@name}
    @socket = new WebSocket "ws://localhost:#{@port}/services"
      ..on 'message', @_on-socket-message
      ..on 'error', @_on-socket-error
      ..on 'open', ~>
        @send do
          name: 'exocom.register-service'
          sender: @name
          payload: payload
          id: '123'
        done!


  send: (request-data) ~>
    @last-sent-message = request-data
    @socket.send JSON.stringify request-data


  _on-socket-error: (error) ~>
    console.log error


  _on-socket-message: (data) ~>
    @received-messages.unshift(JSON.parse data.to-string!)



module.exports = MockService
