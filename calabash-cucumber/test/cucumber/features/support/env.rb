require "calabash-cucumber/wait_helpers"
require "calabash-cucumber/operations"
World(Calabash::Cucumber::Operations)

require "rspec"

if !RunLoop::Environment.xtc?
  require "pry"
  Pry.config.history.file = ".pry-history"
  require "pry-nav"

  require 'pry/config'
  class Pry
      trap('INT') { exit!(1) }
  end
end
