require! {
  'chalk' : {cyan}
  'events' : {EventEmitter}
  '../message-cache/message-cache' : MessageCache
  'ws' : {Server: WebSocketServer}
}
debug = require('debug')('exocom:websocket-subsystem')


# The web sockets endpoint that listens/sends messages from/to services
#
# Emits these events:
# - online: when it is online and ready to go
# - error: for critical issues
# - warn: for non-critical issues
class WebSocketSubsystem extends EventEmitter

  ({@exocom, @logger} = {}) ->
    @server = null
    @port = null

    # Stores the service names and respective web socket
    #
    # format:
    # {
    #   'client 1 name': websocket,
    #   'client 2 name': websocket,
    #   ...
    # }
    @sockets = {}


  # Registers the given websocket as a connection
  # to an instance of the service with the given name
  register-client: ({client-name, websocket}) ->
    @sockets[client-name] = websocket
      ..on 'close', ~>
        @exocom.deregister-client client-name
        @deregister-client client-name


  deregister-client: (client-name) ->
    @sockets[client-name]?.close!
    delete @sockets[client-name]


  close: ->
    | !@server  =>  return
    debug 'websockets going offline'
    @server.close!


  # Listens at the given port
  # by hooking into the given http server instance
  listen: (@port, server) ->
    @server = new WebSocketServer {server, path: '/services'}
      ..on 'connection', @on-connection
      ..on 'listening', ~>
        @logger.log "ExoCom WebSocket listener online at port #{cyan port}"
        @emit 'online', @port
      ..on 'error', (err) ~> @logger.error err


  # called when a new service instance connects
  on-connection: (websocket) ~>
    websocket.on 'message', (message) ~>
      @on-message message, websocket


  # called when a new message from a service instance arrives
  on-message: (message-text, websocket) ->
    request-data = @_filter-incoming-message JSON.parse(message-text)
    @_log-received request-data
    switch
      | request-data.name is \exocom.register-service           =>  @on-service-instance-registration request-data.payload, websocket
      | @invalid-sender request-data.sender, request-data.name  =>  @logger.error "Service '#{request-data.sender}' is not allowed to broadcast the message '#{request-data.name}'"
      | otherwise                                               =>  @on-normal-message-receive request-data


  # called when a service instance registers itself with Exocom
  on-service-instance-registration: (payload, websocket) ->
    @exocom.register-client payload, websocket
    @register-client client-name: payload.name, websocket: websocket


  # called when a service instance sends a normal message
  # i.e. not a registration message
  on-normal-message-receive: (data) ->
    switch (result = @exocom.send-message data)
      | 'success'             =>
      | 'no receivers'        =>  @logger.warning "No receivers for message '#{data.name}' registered"
      | 'missing request id'  =>  @logger.error 'missing request id'
      | 'unknown message'     =>  @logger.error "unknown message: '#{request-data.message}'"
      | _                     =>  @logger.error "unknown result code: '#{@result}'"


  send-message-to-services: (message-data, services) ->
    for service in services
      @send-message-to-service message-data, service


  send-message-to-service: (message-data, service) ->
    internal-message-name = @_internal-message-name message-data.name, for: service
    request-data =
      name: internal-message-name
      id: message-data.id
      payload: message-data.payload
      timestamp: message-data.timestamp
    if message-data.response-to
      request-data.response-time = message-data.response-time
      request-data.response-to = message-data.response-to
    @_log-sending message-data, service
    @sockets[service.name].send JSON.stringify request-data
    result = {[key, value] for key, value of message-data}
    result.name = internal-message-name
    result


  _log-received: ({name, id, response-to}) ->
    | response-to  =>  debug "received '#{name}' with id '#{id}' in response to '#{response-to}'"
    | _            =>  debug "received '#{name}' with id '#{id}'"


  _log-sending: ({name, id, response-to}, service) ->
    | response-to  =>  debug "sending '#{name}' with id '#{id}' in response to '#{response-to}' to '#{service.name}'"
    | _            =>  debug "sending '#{name}' with id '#{id}' to '#{service.name}'"


  # Returns the relevant data from a request
  _filter-incoming-message: (message) ~>
    {
      sender: message.sender
      name: message.name
      payload: message.payload
      response-to: message.response-to
      timestamp: message.timestamp
      id: message.id
    }


  # Translates outgoing message into one that the receiving service will understand
  _internal-message-name: (message-name, {for: service}) ->
    message-parts = message-name.split '.'
    switch
      | !service.internal-namespace                     =>  message-name
      | message-parts.length is 1                       =>  message-name
      | message-parts[0] is service.internal-namespace  =>  message-name
      | otherwise                                       => "#{service.internal-namespace}.#{message-parts[1]}"


  invalid-sender: (sender, message) ->
    !@exocom.client-registry.can-send sender, message



module.exports = WebSocketSubsystem
