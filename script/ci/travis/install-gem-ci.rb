#!/usr/bin/env ruby

require 'luffa'

# @todo Enable code-signing on Travis CI for dylibs

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir working_directory do

  do_system('bundle install')

  do_system('rm -rf calabash-ios-server')
  do_system('git clone --depth 1 --branch master --recursive https://github.com/calabash/calabash-ios-server')
  server_dir = File.expand_path(File.join(working_directory, 'calabash-ios-server'))

  env_vars = { 'CALABASH_SERVER_PATH' => server_dir }

  do_system('rake build_server',
            {:env_vars => env_vars,
             :pass_msg => 'built the framework, frank lib, and dylibs',
             :fail_msg => 'could not build all the libraries'})


  if Luffa::Environment.travis_ci?
    ['dylibs/libCalabashDyn.dylib', 'dylibs/libCalabashDynSim.dylib'].each do |lib|
      Luffa.log_warn("Installing empty dylib to #{lib} on Travis CI")
      system('touch', lib)
    end
  end

  do_system('rake install',
            {:pass_msg => 'successfully used rake to install the gem',
             :fail_msg => 'could not install the gem with rake'})
end
