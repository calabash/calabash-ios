@screenshot
@issue_246
Feature:  Screenshot embed in and out of cucumber world

# undefined method `embed` (NoMethodError) when calling screenshot_and_raise
# https://github.com/calabash/calabash-ios/issues/246

Scenario: screenshot_and_raise in the context of cucumber
  When I use screenshot_and_raise in the context of cucumber
  Then I should get a runtime error

Scenario: screenshot_and_raise outside the context of cucumber
  When I screenshot_and_raise outside the context of cucumber
  Then I should get a runtime error
  But it should not be a NoMethod error for embed

