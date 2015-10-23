#!/usr/bin/env ruby

require "luffa"
require "dotenv"

# Clean install of _this_ version of Calabash
Luffa::Gem.uninstall_gem("calabash-cucumber")
Dir.chdir(File.join("calabash-cucumber")) do
  exit_code = Luffa.unix_command("rake install",
                                 :exit_on_nonzero_status => false)
  if exit_code != 0
    Luffa.unix_command("rm -rf dylibs")
    Luffa.unix_command("mkdir -p dylibs")
    Luffa.unix_command("rm -rf staticlib")
    Luffa.unix_command("mkdir -p staticlib")

    ["dylibs/libCalabashDyn.dylib",
     "dylibs/libCalabashDynSim.dylib",
     "staticlib/calabash.framework.zip",
     "staticlib/libFrankCalabash.a"].each do |library|
       Luffa.unix_command("echo \"touch\" > #{library}")
     end
  end
end

calabash_version = lambda {
  file = File.join("calabash-cucumber", "lib", "calabash-cucumber", "version.rb")
  content = File.read(file)
  regex = /(\d+\.\d+\.\d+(\.pre\d+)?)/
  match = content[regex, 0]

  if !match
    raise "Could not find a VERSION line in '#{file}' with #{regex}"
  end

  match
}.call

xtc_test_dir = File.join("calabash-cucumber", "test", "xtc")
Dir.chdir xtc_test_dir do

  # Force XTC submit to use _this_ version of Calabash
  File.open("Gemfile", "w") do |file|
    file.write("source \"https://rubygems.org\"\n")
    file.write("gem \"calabash-cucumber\", \"#{calabash_version}\"\n")
  end

  Luffa.log_pass("Wrote new Gemfile with calabash-version '#{calabash_version}'")

  # On Travis, the XTC api token and user are _private_ and are available to gem
  # maintainers only.  Pull requests and commits that do not originate from a
  # maintainer skip the XTC step.
  #
  # Locally, the XTC_API_TOKEN, XTC_DEVICE_SET, and XTC_USER can be set in a
  # .env file and accessed with with the dotenv gem, passed on the command line,
  # or exported to the shell.
  #
  # The XCT_API_TOKEN is _private_. The .env should never be committed to git.
  # There is an example .env file provided.
  #
  # Dotenv is _not_ calabash-cucumber gem dependency - it is installed and used
  # only during testing.
  #
  # The .env file should live in test/xtc
  Dotenv.load if File.exist?('.env')
  token = ENV['XTC_API_TOKEN']
  device_set = ENV['XTC_DEVICE_SET']

  unless device_set
    # A collection of device sets that have one iOS >= 8.0 device.
    device_set =
          [
                'd2b869c3', '13629e4e', '6e501bf5', 'beaa6b1e', 'cd93c414',
                '1d7d45da', '4d1f1f17', '529ebd0b', '5189dc60', '953a5c9d',
                '90c31e8c', '55a5742b', '28e55ca5', '615b2706', 'a9209568',
                '154ea192', 'ffd4b340', 'bce0fcdd', 'abfd755e', '64fd338e',
                'd2805bcb', '6463528a', '79ed6ab6', '24bb451d'
          ].sample
  end

  user = ENV['XTC_USER']

  wait_for_results = "--async"

  if ENV["XTC_WAIT_FOR_RESULTS"] == "1"
    wait_for_results = '--no-async'
  end

  args = ['-c', 'cucumber.yml',
          '-p', 'ci',
          '--series', 'travis-ci-calabash-ios-gem',
          '-d', device_set,
          wait_for_results,
          '--user', user,
          "--dsym-file", "CalSmoke-cal.app.dSYM"]

  ipa = 'CalSmoke-cal.ipa'

  cmd = "test-cloud submit #{ipa} #{token} #{args.join(" ")}"

  Luffa.unix_command(cmd, {:pass_msg => "XTC job completed",
                           :fail_msg => "XTC job failed",
                           :obscure_fields => [token, user]})
end

