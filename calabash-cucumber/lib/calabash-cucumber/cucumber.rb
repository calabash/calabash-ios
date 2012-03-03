require 'calabash-cucumber/color_helper'
require 'calabash-cucumber/operations'

World(Calabash::Cucumber::ColorHelper)
World(Calabash::Cucumber::Operations)

AfterConfiguration do
  require 'calabash-cucumber/calabash_steps'
end
