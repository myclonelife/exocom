# manages which client is subscribed to which message on the bus
class SubscriptionManager


  (@routing) ->

    # List of clients that are subscribed to the given message
    #
    # The format is:
    # {
    #   'message 1 name': [
    #     * name: 'client 1 name'
    #       internal-namespace: 'my namespace'
    #     * name: ...
    #   ],
    #   'message 2 name':
    #     ...
    @subscribers = {}


  add-all: ({client-name, service-type}) ->
    for internal-message in @routing[service-type].receives or {}
      @add {internal-message, client-name}


  # Adds the given client to the subscription list for the given message
  add: ({internal-message, client-name}) ->
    external-message-name = @external-message-name {internal-message, service-name: client-name, internal-namespace: @routing[client-name].internal-namespace}
    (@subscribers[external-message-name] or= []).push do
      name: client-name
      internal-namespace: @routing[client-name].internal-namespace


  remove: (client-name) ->
    for message in (@routing[client-name].receives or {})
      external-message = @external-message-name {message, client-name, internal-namespace: @clients[client-name].internal-namespace}
      # TODO: this is broken, make this remove only the client
      delete @subscribers[external-message]


  subscribers-for: (message-name) ->
    @subscribers[message-name]


  # Returns the message name to which the given service would have to subscribe
  # if it wanted to receive the given message expressed in its internal form.
  #
  # Example:
  # - service "tweets" has internal namespace "text-snippets"
  # - it only knows the "text-snippets.create" message
  # - the external message name that it has to subscribe to is "tweets.create"
  external-message-name: ({internal-message, service-name, internal-namespace}) ->
    message-parts = internal-message.split '.'
    switch
    | !internal-namespace               =>  internal-message
    | message-parts.length is 1         =>  internal-message
    | message-parts[0] is service-name  =>  internal-message
    | otherwise                         =>  "#{service-name}.#{message-parts[1]}"



module.exports = SubscriptionManager
