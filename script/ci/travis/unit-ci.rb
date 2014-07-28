#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir working_directory do

  do_system('bundle exec ruby lib/calabash-cucumber/version.rb',
            {:pass_msg => 'lib/calabash-cucumber/version.rb tests passed',
             :fail_msg => 'lib/calabash-cucumber/version.rb tests failed'})

end
