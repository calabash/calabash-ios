#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

install_gem('dotenv')
require 'dotenv'

working_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

# Before script.
install_gem 'json'
uninstall_gem('calabash-cucumber')
install_gem('run_loop', {:prerelease => true})
install_gem('xamarin-test-cloud')
system('script/ci/travis/install-gem-libs.rb')
system('script/ci/travis/install-gem-ci.rb')

xtc_test_dir = File.join(working_dir, 'calabash-cucumber', 'test', 'xtc')
Dir.chdir xtc_test_dir do

  calabash_version = `calabash-ios version`.chomp
  File.open('Gemfile', 'w') do |file|
    file.write("source 'https://rubygems.org'\n")
    file.write("gem 'calabash-cucumber', '#{calabash_version}'")
  end

  log_pass("wrote new Gemfile with calabash-version '#{calabash_version}'")

  # On Travis, the XTC api token is _private_ and is available to gem
  # maintainers.  Pull requests and commits that do not originate from a
  # maintainer skip the XTC step.
  #
  # Locally, the XTC_API_TOKEN and XTC_DEVICE_SET can be set in a .env file and
  # accessed with with the dotenv gem, passed on the command line, or exported
  # to the shell.
  #
  # The XCT_API_TOKEN is _private_. The .env should never be committed to git.
  #
  # Dotenv is _not_ calabash-cucumber gem dependency - it is installed and used
  # only during testing.
  #
  # The .env file should live in test/xtc
  Dotenv.load if File.exist?('.env')
  token = ENV['XTC_API_TOKEN']
  device_set = ENV['XTC_DEVICE_SET']
  unless device_set
    # A collection of device sets that have one iOS 7* device.
    device_set =
          [
                '78c84725', 'dd030a4d', '77388643', 'de3f1384', 'd3f07761',
                'b354dd28', '4d614d40', '7660a1f0', 'dfa1cb5a', 'beb5c652',
                '2ad574d4', '3c9d9e38', 'a690cafd', 'cb8ce9a8', '1b12481d',
                'c4e5ddfb', '58d479d8', '7e8bfc9a', '8cdd13fe', '69329018',
                '4396bc4e', '92f59830', '40d1d879', '2a817e4a'
          ].sample
  end

  if ENV['XTC_WAIT_FOR_RESULTS'] == '0'
    wait_for_results = '--async'
  else
    wait_for_results = '--no-async'
  end

  args = ['-c', 'cucumber.yml',
          '-p', 'ci',
          '--series', 'travis-ci-calabash-ios-gem',
          '-d', device_set,
          wait_for_results]

  ipa = 'chou-cal.ipa'

  cmd = "test-cloud submit #{ipa} #{token} #{args.join(' ')}"

  do_system(cmd, {:pass_msg => 'XTC job completed',
                  :fail_msg => 'XTC job failed',
                  :obscure_fields => [token, device_set]})
end

