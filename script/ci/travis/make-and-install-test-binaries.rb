#!/usr/bin/env ruby

require 'tmpdir'
require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))


spec_resources_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber', 'spec', 'resources'))

Dir.chdir spec_resources_dir do
  do_system('rm -rf LPSimpleExample-cal.app')
  do_system('rm -rf chou.app')
  do_system('rm -rf LPSimpleExample-cal.ipa')
end

cucumber_test_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber', 'test', 'cucumber'))

Dir.chdir cucumber_test_dir do
  do_system('rm -rf LPSimpleExample-cal.app')
end

dylib_test_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber', 'test', 'dylib'))

Dir.chdir dylib_test_dir do
  do_system('rm -rf chou.app')
end

xtc_test_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber', 'test', 'xtc'))

Dir.chdir xtc_test_dir do
  do_system('rm -rf chou-cal.ipa')
end

working_directory = Dir.mktmpdir

Dir.chdir working_directory do

  do_system('git clone --depth 1 --recursive https://github.com/calabash/calabash-ios-server')
  server_dir = File.expand_path(File.join(working_directory, 'calabash-ios-server'))

  Dir.chdir server_dir do
    install_gem 'xcpretty'
    do_system('make framework')
    do_system('zip -y -q -r calabash.framework.zip calabash.framework')
  end

  framework_zip = File.expand_path(File.join(server_dir, 'calabash.framework.zip'))

  do_system('git clone --depth 1 --recursive https://github.com/jmoody/animated-happiness')
  Dir.chdir './animated-happiness/chou' do
    do_system('rm -rf calabash.framework')
    do_system("cp #{framework_zip} ./")
    do_system('unzip calabash.framework.zip')
    do_system('make all')

    do_system("cp -r chou.app #{spec_resources_dir}/")
    do_system("cp -r chou.app #{dylib_test_dir}/")
    do_system("mv chou-cal.ipa #{xtc_test_dir}/")
  end

  do_system('git clone --depth 1 --recursive https://github.com/jmoody/calabash-ios-example.git')
  Dir.chdir './calabash-ios-example' do
    do_system('rm -rf calabash.framework')
    do_system("cp #{framework_zip} ./")
    do_system('unzip calabash.framework.zip')
    do_system('make all')

    do_system("cp -r LPSimpleExample-cal.app #{spec_resources_dir}/")
    do_system("cp -r LPSimpleExample-cal.app #{cucumber_test_dir}/")
    do_system("mv LPSimpleExample-cal.ipa #{spec_resources_dir}/")
  end
end
