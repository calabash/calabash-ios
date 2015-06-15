#!/usr/bin/env ruby
require 'fileutils'

# ARGV[0] can be a git tag, branch, or sha

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

Dir.chdir working_dir do
  do_system('rm -rf run_loop')
  clone_tag = ARGV.fetch(0, 'develop')
  do_system("git clone --branch #{clone_tag} --recursive https://github.com/calabash/run_loop")
end

run_loop_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'run_loop'))

Dir.chdir run_loop_dir do

  do_system('bundle install')
  do_system('rake install')

end

calabash_gem_dir =  File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

# Force calabash to build with the run-loop on the develop branch.
Dir.chdir calabash_gem_dir do

  FileUtils.mkdir_p('.bundle')

  File.open('.bundle/config', 'w') do |file|
    file.write("---\n")
    file.write("BUNDLE_LOCAL__RUN_LOOP: \"#{run_loop_dir}\"\n")
  end

end
