#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

# before_script
uninstall_gem 'calabash-cucumber'
uninstall_gem 'run_loop'

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))


# noinspection RubyStringKeysInHashInspection
env_vars =
      {
            'TRAVIS' => '1',
            'DEVELOPER_DIR' => '/Applications/Xcode.app/Contents/Developer'
      }

Dir.chdir working_dir do

  # before_script
  do_system('script/ci/travis/clone-and-install-run-loop.rb v0.2.1',
            {:env_vars => env_vars})

  do_system('script/ci/travis/install-static-libs.rb',
            {:env_vars => env_vars})

  do_system('script/ci/travis/bundle-install.rb',
            {:env_vars => env_vars})

  # test scripts
  do_system('script/ci/travis/install-gem-ci.rb',
            {:env_vars => env_vars})

  do_system('script/ci/travis/rspec-ci.rb',
            {:env_vars => env_vars})

  do_system('script/ci/travis/unit-ci.rb',
            {:env_vars => env_vars})

  do_system('script/ci/travis/cucumber-ci.rb --tags ~@no_ci',
            {:env_vars => env_vars})

end
