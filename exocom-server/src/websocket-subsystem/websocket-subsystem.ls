require! {
  'events' : {EventEmitter}
  '../message-cache/message-cache' : MessageCache
  'ws' : {Server: WebSocketServer}
}
debug = require('debug')('exocom:websocket-subsystem')


# The web sockets endpoint that listens/sends messages from/to services
#
# Emits these events:
# - error: when it cannot bind to the given port
# - online: when it is online and ready to go
class WebSocketSubsystem extends EventEmitter

  (@exocom) ->
    @server = null
    @port = null

    # Stores the service names and respective web socket
    @service-sockets = {}


  # Registers the given websocket as a connection
  # to an instance of the service with the given name
  register-service-instance: ({service-name, websocket}) ->
    @service-sockets[service-name] = websocket
      ..on 'close', ~>
        @exocom.remove-routing-config {service-name}
        @deregister-service-instance {service-name}


  deregister-service-instance: ({service-name}) ->
    @service-sockets[service-name]?.close!
    delete @service-sockets[service-name]


  close: ->
    | !@server  =>  return
    debug 'websockets going offline'
    @server.close!


  # Listens at the given port
  # by hooking into the given http server instance
  listen: (@port, server) ->
    @server = new WebSocketServer {server, path: '/services'}
      ..on 'connection', @on-connection
      ..on 'listening', ~> @emit 'online', @port
      ..on 'error', (err) ~> @emit 'error', err


  # called when a new service instance connects
  on-connection: (websocket) ~>
    websocket.on 'message', (message) ~>
      @on-message(message, websocket)


  # called when a new message from a service instance arrives
  on-message: (message, websocket) ->
    request-data = @_parse-request JSON.parse(message)
    @_log-received request-data
    switch
      | request-data.name is \exocom.register-service           =>  @on-service-instance-registration request-data.payload, websocket
      | @invalid-sender request-data.sender, request-data.name  =>  @emit 'error', "Service '#{request-data.sender}' is not allowed to broadcast the message '#{request-data.name}'"
      | otherwise                                               =>  @on-normal-message-receive request-data


  # called when a service instance registers itself with Exocom
  on-service-instance-registration: (payload, websocket) ->
    @exocom.add-routing-config payload, websocket
    @register-service-instance service-name: payload.name, websocket: websocket


  # called when a service instance sends a normal message
  # i.e. not a registration message
  on-normal-message-receive: (data) ->
    switch (result = @exocom.send-message data)
      | 'success'             =>
      | 'no receivers'        =>  @emit 'warn', "No receivers for message '#{data.name}' registered"
      | 'missing request id'  =>  @emit 'error', 'missing request id'
      | 'unknown message'     =>  @emit 'error', "unknown message: '#{request-data.message}'"
      | _                     =>  @emit 'error', "unknown result code: '#{@result}'"


  send-message-to-services: (message-data, services) ->
    for service in services
      @send-message-to-service message-data, service


  send-message-to-service: (message-data, service) ->
    translated-message-name = @_translate message-data.name, for: service
    request-data =
      name: translated-message-name
      id: message-data.id
      payload: message-data.payload
      timestamp: message-data.timestamp
    if message-data.response-to
      request-data.response-time = message-data.response-time
      request-data.response-to = message-data.response-to
    @_log-sending message-data, service
    @service-sockets[service.name].send JSON.stringify request-data
    result = {[key, value] for key, value of message-data}
    result.name = translated-message-name
    result


  _log-received: ({name, id, response-to}) ->
    | response-to  =>  debug "received '#{name}' with id '#{id}' in response to '#{response-to}'"
    | _            =>  debug "received '#{name}' with id '#{id}'"


  _log-sending: ({name, id, response-to}, service) ->
    | response-to  =>  debug "sending '#{name}' with id '#{id}' in response to '#{response-to}' to '#{service.name}'"
    | _            =>  debug "sending '#{name}' with id '#{id}' to '#{service.name}'"


  # Returns the relevant data from a request
  _parse-request: (req) ~>
    {
      sender: req.sender
      name: req.name
      payload: req.payload
      response-to: req.response-to
      timestamp: req.timestamp
      id: req.id
    }


  # Translates outgoing message into one that the receiving service will understand
  _translate: (message-name, {for: service}) ->
    message-parts = message-name.split '.'
    switch
      | !service.internal-namespace                     =>  message-name
      | message-parts.length is 1                       =>  message-name
      | message-parts[0] is service.internal-namespace  =>  message-name
      | otherwise                                       => "#{service.internal-namespace}.#{message-parts[1]}"


  invalid-sender: (sender, message) ->
    !@exocom.client-registry.can-send sender, message



module.exports = WebSocketSubsystem
