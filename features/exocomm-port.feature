Feature: Configuring the ExoComm port

  As a developer
  I want to be able to configure the ExoComm port that my ExoRelay instance is talking to
  So that I have flexibility in my test setup.

  Rules:
  - the default ExoComm port is 3010
  - provide a custom ExoComm port via the "exocommPort" constructor parameter


  Scenario: the user does not provide the ExoComm port
    When I create an ExoRelay instance that uses the default ExoComm port: "new ExoRelay()"
    Then this instance uses the ExoComm port 3010


  Scenario: the user provides an available ExoComm port
    When I create an ExoRelay instance that uses a custom ExoComm port: "new ExoRelay exocommPort: 3011"
    Then this instance uses the ExoComm port 3011
