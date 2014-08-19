#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))


working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

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

  do_system('touch staticlib/calabash.framework.zip',
            {:pass_msg => 'installed (empty) staticlib/calabash.framework.zip',
             :fail_msg => 'could not install (empty) staticlib/calabash.framework.zip'})

  do_system('touch staticlib/libFrankCalabash.a',
            {:pass_msg => 'installed (empty) staticlib/libFrankCalabash.a',
             :fail_msg => 'could not install (empty) staticlib/libFrankCalabash.a'})

  do_system 'mkdir -p dylibs'

  dylibs = ['dylibs/libCalabashDyn.dylib', 'dylibs/libCalabashDynSim.dylib']
  dylibs.each do |dylib|
    do_system("touch #{dylib}",
              {:pass_msg => "installed (empty) #{dylib}",
               :fail_msg => "could not install (empty) #{dylib}"})
  end
end

exit 0
