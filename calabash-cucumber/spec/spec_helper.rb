require 'rspec'
require 'calabash-cucumber/utils/logging'

include Calabash::Cucumber::Logging

# spec_helper.rb
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end

  def capture_stderr
    out = StringIO.new
    $stderr = out
    yield
    return out
  ensure
    $stderr = STDERR
  end
end
