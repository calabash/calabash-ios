require 'rspec'
require 'calabash-cucumber/utils/logging'

include Calabash::Cucumber::Logging

# spec_helper.rb
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
