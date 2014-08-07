#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

cucumber_args = "#{ARGV.join(' ')}"

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber/test/cucumber'))

# on-simulator tests of features in test/cucumber
Dir.chdir(working_directory) do

  do_system 'rm -rf Gemfile'
  do_system 'rm -rf Gemfile.lock'
  do_system 'rm -rf .bundle'
  do_system 'rm -rf vendor'

  do_system('bundle install',
            {:pass_msg => 'bundled',
             :fail_msg => 'could not bundle'})

  # remove any stale targets
  do_system('bundle exec calabash-ios sim reset',
            {:pass_msg => 'reset the simulator',
             :fail_msg => 'could not reset the simulator'})


  # todo - parse the config/cucumber.yml file for this info
  profiles =
        {
              :sim61_4in => 'iPhone Retina (4-inch) - Simulator - iOS 6.1',
              :sim71_4in => 'iPhone Retina (4-inch) - Simulator - iOS 7.1',
              :sim61r => 'iPhone Retina (3.5-inch) - Simulator - iOS 6.1',
              :sim71r => 'iPhone Retina (3.5-inch) - Simulator - iOS 7.1',
              :sim61_ipad_r => 'iPad Retina - Simulator - iOS 6.1',
              :sim71_ipad_r => 'iPad Retina - Simulator - iOS 7.1',
              :sim61_sl => 'iPhone (3.5-inch) - Simulator - iOS 6.1 (launched with ios-sim)'
        }

  if travis_ci?
    profiles[:sim70_64b] = 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.0'
    profiles[:sim70_ipad_r_64b] = 'iPad Retina (64-bit) - Simulator - iOS 7.0'
  else
    profiles[:sim71_64b] = 'iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.1'
    profiles[:sim71_ipad_r_64b] = 'iPad Retina (64-bit) - Simulator - iOS 7.1'
  end

  # noinspection RubyStringKeysInHashInspection
  env_vars =
        {
              'APP_BUNDLE_PATH' => './LPSimpleExample-cal.app',
              'DEVELOPER_DIR' => '/Applications/Xcode.app/Contents/Developer'
        }
  passed_sims = []
  failed_sims = []
  profiles.each do |profile, name|
    cucumber_cmd = "bundle exec cucumber -p #{profile.to_s} #{cucumber_args}"

    exit_code = do_system(cucumber_cmd, {:exit_on_nonzero_status => false,
                                         :env_vars => env_vars})
    if exit_code == 0
      passed_sims << name
    else
      failed_sims << name
    end
  end

  puts '=== SUMMARY ==='
  puts ''
  puts 'PASSING SIMULATORS'
  puts "#{passed_sims.join("\n")}"
  puts ''
  puts 'FAILING SIMULATORS'
  puts "#{failed_sims.join("\n")}"

  sims = profiles.count
  passed = passed_sims.count
  failed = failed_sims.count

  puts ''
  puts "passed on '#{passed}' out of '#{sims}'"


  # if none failed then we have success
  exit 0 if failed == 0

  # the travis ci environment is not stable enough to have all tests passing
  exit failed unless travis_ci?

  # we'll take 75% passing as good indicator of health
  expected = 75
  actual = ((passed.to_f/sims.to_f) * 100).to_i

  if actual >= expected
    puts "PASS:  we failed '#{failed}' sims, but passed '#{actual}%' so we say good enough"
    exit 0
  else
    puts "FAIL:  we failed '#{failed}' sims, which is '#{actual}%' and not enough to pass"
    exit 1
  end
end