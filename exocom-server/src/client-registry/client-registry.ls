require! {
  'jsonic'
  'remove-value'
  'require-yaml'
}


class ClientRegistry

  ({service-messages = '{}'} = {}) ->

    # List of messages that are received by the applications services
    #
    # the format is:
    # {
    #   'service 1 name':
    #     receives: ['message 1', 'message 2']
    #     sends: ['message 3', 'message 4']
    #     internal-namespace: 'my internal namespace'
    #   'service 2 name':
    #     ...
    @routing = {}

    # List of clients that are currently registered
    #
    # The format is:
    # {
    #   'client 1 name':
    #     name: ...
    #     namespace: ...
    #   'client 2 name':
    #     ...
    @clients = {}

    # List of clients that are subscribed to the given message
    #
    # The format is:
    # {
    #   'message 1 name':
    #     receivers:
    #       * name: ...
    #       * name: ...
    #   'message 2 name':
    #     ...
    @subscribers = {}

    @_set-routing service-messages


  # Adds service routing configurations to the given setup
  register-service: (service) ->
    @clients[service.name] =
      name: service.name
      internal-namespace: @routing[service.name].internal-namespace
    for message in (@routing[service.name].receives or {})
      external-message = @external-message-name {message, service-name: service.name, internal-namespace: @routing[service.name].internal-namespace}
      @subscribers[external-message] or= {}
      @subscribers[external-message].receivers or= []
      @subscribers[external-message].receivers.push do
        name: service.name
        internal-namespace: @routing[service.name].internal-namespace


  deregister-service: (service-name) ->
    for message in (@routing[service-name].receives or {})
      external-message = @external-message-name {message, service-name, internal-namespace: @clients[service-name].internal-namespace}
      delete @subscribers[external-message]
    delete @clients[service-name]


  # Returns the clients that are subscribed to the given message
  subscribers-for: (message-name) ->
    | @subscribers[message-name]  =>  @subscribers[message-name].receivers


  can-send: (sender, message) ->
    @routing[sender].sends |> (.includes message)


  # Returns the message name to which the given service would have to subscribe
  # if it wanted to receive the given message expressed in its internal form.
  #
  # Example:
  # - service "tweets" has internal namespace "text-snippets"
  # - it only knows the "text-snippets.create" message
  # - the external message name that it has to subscribe to is "tweets.create"
  external-message-name: ({message, service-name, internal-namespace}) ->
    message-parts = message.split '.'
    switch
    | !internal-namespace               =>  message
    | message-parts.length is 1         =>  message
    | message-parts[0] is service-name  =>  message
    | otherwise                         =>  "#{service-name}.#{message-parts[1]}"


  # Returns the external name for the given message sent by the given service,
  # i.e. how the sent message should appear to the other services.
  #
  # Example:
  # - service "tweets" has internal name "text-snippets"
  # - it sends the message "text-snippets.created" to exocom
  # - exocom converts this message to "tweets.created"
  outgoing-message-name: (message, service) ->
    message-parts = message.split '.'
    switch
    | message-parts.length is 1                       =>  message
    | message-parts[0] is service.internal-namespace  =>  "#{service.name}.#{message-parts[1]}"
    | otherwise                                       =>  message


  _set-routing: (routing-data) ->
    for service in jsonic(routing-data)
      @routing[service.name] =
        receives: service.receives
        sends: service.sends
        internal-namespace: service.namespace



module.exports = ClientRegistry
