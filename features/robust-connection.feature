Feature: resilient connecting to ExoCom

  As an Exosphere operator
  I want ExoRelay to keep trying to connect to ExoCom
  So that I can deploy ExoCom and Exoservices in any order.

  Rules
  - failed connections to ExoCom are retried every second until a connection is made

  Scenario: connect to ExoCom instance that comes online after ExoRelay
    Given a new ExoRelay instance
    When an ExoCom instance comes online 1 second later
    Then ExoRelay connects to ExoCom
