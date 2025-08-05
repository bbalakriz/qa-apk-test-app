Feature: CheckIn Screen PNR Entry
  As a user
  I want to enter my PNR and last name on the check-in screen
  So that I can validate the check-in process

  Scenario: User enters invalid PNR and last name and sees error message
    Given I am on the check-in screen
    When I enter PNR "G3QP4R"
    And I enter last name "Qureshi"  
    And I click the get started button
    Then I should see an appropriate response