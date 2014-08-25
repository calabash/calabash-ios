#!/usr/bin/env ruby
require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))


cal_repo_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'calabash-ios'))

# Stage the sim dylib if it does not already exist.
# This is a proxy for building the dylib from sources which is not supported yet
gem_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

calabash_version = nil
Dir.chdir(gem_dir) do
  dylib_dir = File.join(gem_dir, 'dylibs')
  FileUtils.mkdir_p dylib_dir
  sim_dylib = File.join(dylib_dir, 'libCalabashDynSim.dylib')
  device_dylib = File.join(dylib_dir, 'libCalabashDyn.dylib')
  do_system("touch '#{device_dylib}'")

  ### => WARNING <= ###
  # brute force delete! Remove this once we can build dylibs in the calabash-ios-server
  FileUtils.rm_rf sim_dylib

  unless File.exist? sim_dylib
    do_system("curl --silent -o #{sim_dylib} https://s3.amazonaws.com/littlejoysoftware/public/libCalabashDynSim.dylib",
              { :pass_msg => "downloaded '#{sim_dylib}'",
                :fail_msg => 'could not download sim dylib from S3'})
  end

  do_system('bundle exec rake install',
            {:pass_msg => 'successfully used rake to install the gem',
             :fail_msg => 'could not install the gem with rake'})
  calabash_version = `bundle exec calabash-ios version`.chomp
end


working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber/test/dylib'))

# on-simulator tests of features in test/cucumber
Dir.chdir(working_directory) do

  do_system 'rm -rf Gemfile'
  do_system 'rm -rf Gemfile.lock'
  do_system 'rm -rf .bundle'
  do_system 'rm -rf vendor'

  do_system('rm -rf run-loop')
  do_system('git clone --depth 1 --recursive https://github.com/calabash/run_loop run-loop')
  run_loop_gem_dir = File.join(working_directory, 'run-loop')

  File.open('Gemfile', 'w') do |file|
    file.write("source 'https://rubygems.org'\n")
    file.write("gem 'calabash-cucumber', '#{calabash_version}'\n")
    file.write("gem 'run_loop', :github => 'calabash/run_loop', :branch => 'master'\n")
  end

  FileUtils.mkdir_p('.bundle')

  File.open('.bundle/config', 'w') do |file|
    file.write("---\n")
    file.write("BUNDLE_LOCAL__RUN_LOOP: \"#{run_loop_gem_dir}\"\n")
    file.write("BUNDLE_LOCAL__CALABASH-CUCUMBER: \"#{cal_repo_dir}\"\n")
  end

  do_system('bundle install',
            {:pass_msg => 'bundled',
             :fail_msg => 'could not bundle'})

  # remove any stale targets
  do_system('bundle exec calabash-ios sim reset',
            {:pass_msg => 'reset the simulator',
             :fail_msg => 'could not reset the simulator'})

  # noinspection RubyStringKeysInHashInspection
  env_vars =
        {
              'APP' => './chou.app',
              'DEVELOPER_DIR' => '/Applications/Xcode.app/Contents/Developer'
        }

  do_system('bundle exec cucumber',
            {:env_vars => env_vars})
end
