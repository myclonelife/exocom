require! {
  './subscription-manager' : SubscriptionManager
  chai : {expect}
}


describe 'SubscriptionManager', ->

  before-each ->
    @subscription-manager = new SubscriptionManager


  describe 'external-message-name', (...) ->

    it "does not convert messages that don't match the format", ->
      result = @subscription-manager.external-message-name do
        internal-message: 'foo bar'
        service-name: 'tweets'
        internal-namespace: 'text-snippets'
      expect(result).to.eql 'foo bar'

    it 'does not convert messages that have the same internal and external namespace', ->
      result = @subscription-manager.external-message-name do
        internal-message: 'users.create'
        service-name: 'users'
        internal-namespace: 'users'
      expect(result).to.eql 'users.create'

    it 'does not convert messages if the service has no internal namespace', ->
      result = @subscription-manager.external-message-name do
        internal-message: 'users.create'
        service-name: 'users'
        internal-namespace: ''
      expect(result).to.eql 'users.create'


    it 'converts messages into the external namespace of the service', ->
      result = @subscription-manager.external-message-name do
        internal-message: 'text-snippets.create'
        service-name: 'tweets'
        internal-namespace: 'text-snippets'
      expect(result).to.eql 'tweets.create'