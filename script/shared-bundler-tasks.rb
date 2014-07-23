#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), 'ci_helpers'))


working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', 'calabash-cucumber'))

# Enable binaries to be installed.
#
# calabash-cucumber at /Users/travis/build/calabash/calabash-ios/calabash-cucumber did not have a valid gemspec.
# This prevents bundler from installing bins or native extensions, but that may not affect its functionality.
# The validation message from Rubygems was:
#  ["staticlib/calabash.framework.zip"] are not files
Dir.chdir working_directory do
  do_system 'touch calabash.framework'
  do_system('zip -r calabash.framework.zip calabash.framework',
            {:pass_msg => 'zipped calabash.framework',
             :fail_msg => 'could not zip calabash.framework'})

  do_system 'mkdir -p staticlib'
  do_system 'mv calabash.framework.zip staticlib/'
  do_system 'rm calabash.framework'
  do_system('gem install --no-document bundler',
            {:pass_msg => 'installed gem',
             :fail_msg => 'could not install gem'})

  do_system('bundle install',
            {:pass_msg => 'bundled',
             :fail_msg => 'could not bundle'})
end

exit 0
