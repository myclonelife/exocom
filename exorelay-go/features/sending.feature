Feature: Sending outgoing messages

  As an Exoservice developer
  I want my service to be able to send messages to other Exosphere services
  So that it can interact with the rest of the application.

  Rules:
  - call "send" on your ExoRelay instance have it send out the given message
  - provide the message to send as the first parameter
  - provide payload for the message as the second parameter
  - the payload can be either a string, an array, or a Hash


  Background:
    Given ExoCom runs at port 4100
    And an ExoRelay instance running inside the "test-service" service on port 4100


  Scenario: sending a message without payload
    When sending a message with the name "hello-world" and no payload
    Then ExoRelay makes the WebSocket request:
      """
      {
        "name": "hello-world",
        "sender": "test-service"
      }
      """


  Scenario: sending a message with a populated Hash as payload
    When sending the message:
      """
      {
        "name": "hello",
        "payload": {
          "name": "world"
        }
      }
      """
    Then ExoRelay makes the WebSocket request:
      """
      {
        "name": "hello",
        "sender": "test-service",
        "payload": {
          "name": "world"
        }
      }
      """

  Scenario: sending a message with an array as payload
    When sending the message:
      """
      {
        "name": "sum",
        "payload": [1, 2, 3]
      }
      """
    Then ExoRelay makes the WebSocket request:
      """
      {
        "name": "sum",
        "sender": "test-service",
        "payload": [1, 2, 3]
      }
      """

  Scenario: trying to send an empty message
    When trying to send an empty message
    Then ExoRelay emits the error "ExoRelay.Send cannot send empty messages"
