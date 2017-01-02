require! {
  'jsonic'
  'remove-value'
  'require-yaml'
  './subscription-manager' : SubscriptionManager
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
    @_set-routing service-messages

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


    @subscriptions = new SubscriptionManager @routing



  # Adds service routing configurations to the given setup
  register-client: (service) ->

    # add to clients list
    @clients[service.name] =
      name: service.name
      internal-namespace: @routing[service.name].internal-namespace

    # add subscriptions
    @subscriptions.add-all client-name: service.name, internal-messages: @routing[service.name].receives


  deregister-client: (service-name) ->

    # remove subscriptions
    @subscriptions.remove service-name

    # remove from clients list
    delete @clients[service-name]


  # Returns the clients that are subscribed to the given message
  subscribers-for: (message-name) ->
    @subscriptions.subscribers-for message-name


  can-send: (sender, message) ->
    @routing[sender].sends |> (.includes message)


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
