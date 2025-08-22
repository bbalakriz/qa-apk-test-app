Feature: Launch App

  @smoke @launch
  Scenario: Open the app successfully
    Given the app is launched 

  @regression @relaunch
  Scenario: Kill, relaunch app and click Press Me button
    Given the app is killed
    And the app is relaunched
    When I click the "Press Me" button
    Then the app should respond to the button click     