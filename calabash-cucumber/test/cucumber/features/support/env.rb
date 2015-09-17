require 'calabash-cucumber/cucumber'

require 'rspec'
require 'luffa'

# Pry is not allowed on the Xamarin Test Cloud.  This will force a validation
# error if you mistakenly submit a binding.pry to the Test Cloud.
if !ENV['XAMARIN_TEST_CLOUD']
  require 'pry'
  Pry.config.history.file = '.pry-history'
  require 'pry-nav'
end

