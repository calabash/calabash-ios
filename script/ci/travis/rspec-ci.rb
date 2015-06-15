#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir working_directory do

  do_system('bundle exec rake unit',
            {:pass_msg => 'rspec tests passed',
             :fail_msg => 'rspec tests failed'})

end
