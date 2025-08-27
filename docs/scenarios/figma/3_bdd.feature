Feature: CTA completes action
  Scenario: User taps CTA and sees completed status
    Given the landing page is initialized
    When the user taps the "ctaButton"
    Then #statusMessage is set to "Action completed"
