#!/usr/bin/env ruby
require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir working_dir do

  do_system('rm -rf run_loop')

  do_system('git clone --recursive https://github.com/calabash/run_loop')

end

run_loop_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'run_loop'))

Dir.chdir run_loop_dir do

  do_system('bundle install')
  do_system('bundle exec rake install')

end

calabash_gem_dir =  File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir calabash_gem_dir do

  puts "calabash gem dir = '#{calabash_gem_dir}'"
  FileUtils.mkdir_p('.bundle')

  File.open('.bundle/config', 'w') do |file|
    file.write("---\n")
    file.write("BUNDLE_LOCAL__RUN_LOOP: \"#{run_loop_dir}\"\n")
  end

end


