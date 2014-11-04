#!/usr/bin/env ruby
require 'open3'
require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir working_directory do

  do_system('bundle install')
  do_system('rake install',
            {:pass_msg => 'successfully used rake to install the gem',
             :fail_msg => 'could not install the gem with rake'})
end
