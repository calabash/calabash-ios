#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir working_directory do

  do_system('rm -rf calabash-ios-server')
  do_system('git clone --depth 1 --recursive https://github.com/calabash/calabash-ios-server')
  server_dir = File.expand_path(File.join(working_directory, 'calabash-ios-server'))

  do_system('rm -rf staticlib')
  do_system('rm -rf dylibs')
  # noinspection RubyStringKeysInHashInspection
  env_vars =
        {
              'CALABASH_SERVER_PATH' => server_dir,
              'CALABASH_NO_DYLIBS' => travis_ci? ? '1' : '0'
        }

  # Xcode 6 supports dylib targets, but dylibs require code-signing which
  # requires a bunch of Travis CI configuration.
  # @todo Enable code-signing on Travis CI for dylibs
  if xcode_version_gte_6?
    do_system('rake build_server',
              {:env_vars => env_vars,
               :pass_msg => 'built the framework, frank lib, and dylibs',
               :fail_msg => 'could not build all the libraries'})
  else
    # Expecting failures on Xcode 5.1.1 that do not have injected .xcspecs.
    exit_code = do_system('rake build_server',
                          {:env_vars => env_vars,
                           :pass_msg => 'built the framework, frank lib, and dylibs',
                           :exit_on_nonzero_status => false})
    if exit_code == 0
      log_fail 'did not expect to pass the rake build_server task; waiting for dylib targets'
    else
      log_pass 'expected to fail the rake build_server task; waiting for dylib targets'
    end
  end

  ['staticlib/calabash.framework.zip', 'staticlib/libFrankCalabash.a'].each do |lib|
    do_system("[ -e #{lib} ]",
              {:pass_msg => "installed #{lib}",
               :fail_msg => "did not install #{lib}"})
  end

  # Xcode 6 supports dylib targets, but dylibs require code-signing which
  # requires a bunch of Travis CI configuration.
  # @todo Enable code-signing on Travis CI for dylibs
  unless travis_ci?
    if xcode_version_gte_6?
      ['dylibs/libCalabashDyn.dylib', 'dylibs/libCalabashDynSim.dylib'].each do |lib|
        do_system("[ -e #{lib} ]",
                  {:pass_msg => "installed #{lib}",
                   :fail_msg => "did not install #{lib}"})
      end
    else
      # Expecting failures on Xcode 5.1.1 that do not have injected .xcspecs.
      ['dylibs/libCalabashDyn.dylib', 'dylibs/libCalabashDynSim.dylib'].each do |lib|
        exit_code = do_system("[ -e #{lib} ]",
                              {:pass_msg => "installed #{lib}",
                               :exit_on_nonzero_status => false})
        if exit_code == 0
          log_fail "did not expect to be able to install dylib '#{lib}'; waiting for dylib targets"
        else
          log_pass "expected _not_ to be able install dylib '#{lib}'; waiting for dylib targets"
        end
      end
    end
  end
end

exit 0
