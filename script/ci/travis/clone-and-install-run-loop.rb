#!/usr/bin/env ruby
require 'fileutils'

clone_tag = "#{ARGV.join(' ')}"

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir working_dir do

  do_system('rm -rf run_loop')

  if clone_tag
    do_system("git clone --branch #{clone_tag} --recursive https://github.com/calabash/run_loop")
  else
    do_system('git clone --recursive https://github.com/calabash/run_loop')
  end

end

run_loop_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'run_loop'))

Dir.chdir run_loop_dir do

  # rake is not part of the gem until 1.0.0.pre1
  do_system('bundle install')
  #do_system('bundle exec rake install')
  do_system('rake install')

end

calabash_gem_dir =  File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir calabash_gem_dir do

  FileUtils.mkdir_p('.bundle')

  File.open('.bundle/config', 'w') do |file|
    file.write("---\n")
    file.write("BUNDLE_LOCAL__RUN_LOOP: \"#{run_loop_dir}\"\n")
  end

end


