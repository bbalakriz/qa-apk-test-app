Feature: Button interaction

  Scenario: User presses the button and sees a response
    Given the app is launched
    When I press the "PressButton"
    Then I should see the response message
