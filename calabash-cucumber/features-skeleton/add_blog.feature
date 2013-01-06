Feature: Add blog
  As a user of Cucumber,
  it is important that I understand that Cucumber and BDD specifications
  have value beyond automation.

  I want the people that should be the most interested (the business!)
  to be able to understand and contribute to specifications.

  Features and scenarios should be phrased in
  the high-level language of my domain.

Scenario: Adding a wordpress.com blog
  Allow users to access wordpress.com blogs
  from the app, by providing credentials.

  Given I am on the Welcome Screen
  When I choose to add my WordPress.com blog
  And I present valid credentials
  Then I should go to Posts
  And I should see the recent posts from my blog


