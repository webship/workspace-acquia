Feature: The Acquia Cloud plugin on a project row
  Once the plugin is activated and installed, every site row carries the ACQUIA menu, and the Plugins
  page lists the plugin with its four steps.

  @needs-project-dev
  Scenario: A site row offers the ACQUIA menu, captioned with its link state
    Given I am on "/dev"
     Then the element ".act-menu-acquia" should be displayed
      And I should see "ACQUIA"
      And the element ".act-menu-acquia + .act-status" should be displayed

  @needs-project-dev
  Scenario: An unlinked project's menu opens and says how to link it
    Given I am on "/dev"
      And I click on the element ".project-row .act-menu-acquia button"
     Then ".uk-dropdown.uk-open" should be visible
      And I should see "Not linked to Acquia Cloud"

  # The Plugins page names each plugin; the package is on the plugin's own page (the row shows it on hover only).
  Scenario: The plugin is listed on the Plugins page, and its own page names its package
    Given I am on "/settings/plugins"
     Then I should see "Acquia Cloud"
     When I go to "/settings/plugin/acquia"
     Then I should see "@webship.co/workspace-acquia"

  # The AI folders are searched by name: with every plugin on, a folder lists more than one page of items.
  Scenario: The AI Agents folder lists the agent the plugin ships
    Given I am on "/ai-agents?q=acquia-deployer"
     Then I should see "acquia-deployer"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills?q=acquia-hosting"
     Then I should see "acquia-hosting"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands?q=acquia-status"
     Then I should see "acquia-status"

  Scenario: The AI Prompts folder lists the prompt the plugin ships
    Given I am on "/ai-prompts?q=acquia-test-then-deploy"
     Then I should see "acquia-test-then-deploy"
