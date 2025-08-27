Feature: Login status update
  Scenario: User taps login and sees success
    Given the app is initialized on the login screen
    When the user taps the "loginButton"
    Then #statusMessage is set to "Login successful"
