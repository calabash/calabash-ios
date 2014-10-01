#!/usr/bin/env ruby

require 'erb'
require 'yaml'

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


  cucumber_profiles = File.expand_path('config/cucumber.yml')
  evaled_erb = ERB.new(File.read cucumber_profiles)
  # noinspection RubyResolve
  parsed_yaml = YAML.load(evaled_erb.result)
  simulators_str = parsed_yaml['simulators'].split('=')[1..-1].join(' =').gsub(/=>/, ' => ').gsub!(/\A"|"\Z/, '')
  hash_ready = simulators_str[1..simulators_str.length-2]
  tokens = hash_ready.split(',').map { |elm| elm.strip }
  simulator_profiles = {}
  tokens.each do |token|
    key_value = token.split('=>').map { |elm| elm.strip }
    simulator_profiles[key_value[0].tr(':', '').to_sym] = key_value[1].gsub!(/\A"|"\Z/, '')
  end

  if travis_ci?
    profiles =
          {
                #:ipad2 => simulator_profiles[:ipad2],
                # Not yet, maybe never
                #:ipad2_mid => simulator_profiles[:ipad2_mid],
                #:ipad2_min => simulator_profiles[:ipad2_min],

                :air => simulator_profiles[:air],
                # Not yet, maybe never
                #:air_mid => simulator_profiles[:air_mid],
                #:air_min => simulator_profiles[:air_min],

                #:ipad => simulator_profiles[:ipad],
                # Stalls on Travis CI
                #:ipad_mid => simulator_profiles[:ipad_mid],
                # Not yet, maybe never
                #:ipad_min => simulator_profiles[:ipad_min],

                #:iphone4s => simulator_profiles[:iphone4s],
                # Not yet, maybe never
                #:iphone4s_mid => simulator_profiles[:iphone4s_mid],
                #:iphone4s_min => simulator_profiles[:iphone4s_min],

                #:iphone5s => simulator_profiles[:iphone5s],
                # Not yet, maybe never
                #:iphone5s_mid => simulator_profiles[:iphone5s_mid],
                #:iphone5s_min => simulator_profiles[:iphone5s_min],

                #:iphone5 => simulator_profiles[:iphone5],
                # Not yet, maybe never
                #:iphone5_mid => simulator_profiles[:iphone5_mid],
                #:iphone5_min => simulator_profiles[:iphone5_min]
          }
  else
    profiles =
          {
                :ipad2 => simulator_profiles[:ipad2],
                :ipad2_mid => simulator_profiles[:ipad2_mid],
                :ipad2_min => simulator_profiles[:ipad2_min],

                :air => simulator_profiles[:air],
                :air_mid => simulator_profiles[:air_mid],
                :air_min => simulator_profiles[:air_min],

                :ipad => simulator_profiles[:ipad],
                :ipad_mid => simulator_profiles[:ipad_mid],
                :ipad_min => simulator_profiles[:ipad_min],

                :iphone4s => simulator_profiles[:iphone4s],
                :iphone4s_mid => simulator_profiles[:iphone4s_mid],
                :iphone4s_min => simulator_profiles[:iphone4s_min],

                :iphone5s => simulator_profiles[:iphone5s],
                :iphone5s_mid => simulator_profiles[:iphone5s_mid],
                :iphone5s_min => simulator_profiles[:iphone5s_min],

                :iphone5 => simulator_profiles[:iphone5],
                :iphone5_mid => simulator_profiles[:iphone5_mid],
                :iphone5_min => simulator_profiles[:iphone5_min]
          }
  end

  # Travis CI on Xcode 5.1.1 has a hard time with 64 bit simulators.
  if travis_ci? and not xcode_version_gte_6?
    profiles[:air] = simulator_profiles[:air_mid]
    profiles[:iphone5s] = simulator_profiles[:iphone5s_mid]
  end

  # noinspection RubyStringKeysInHashInspection
  env_vars =
        {
              'APP_BUNDLE_PATH' => './LPSimpleExample-cal.app',
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
