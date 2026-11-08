Feature: The Acquia Cloud plugin on a project row
  Once the plugin is activated and installed, every site row carries the ACQUIA menu, and the Plugins
  page lists the plugin with its four steps.

  Scenario: A site row offers the ACQUIA menu, captioned with its link state
    Given I am on "/dev"
     Then the element ".act-menu-acquia" should be displayed
      And I should see "ACQUIA"
      And the element ".act-menu-acquia + .act-status" should be displayed

  Scenario: An unlinked project's menu opens and says how to link it
    Given I am on "/dev"
      And I click on the element ".project-row .act-menu-acquia button"
     Then ".uk-dropdown.uk-open" should be visible
      And I should see "Not linked to Acquia Cloud"

  Scenario: The plugin is listed on the Plugins page
    Given I am on "/settings/plugins"
     Then I should see "Acquia Cloud"
      And I should see "@webship.co/workspace-acquia"
