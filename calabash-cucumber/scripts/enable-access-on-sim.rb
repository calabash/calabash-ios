#!/usr/bin/ruby

require 'open3'
require 'fileutils'

module Calabash
  module Cucumber
    module Logging
      def _warn(msg)
        begin
          warn "\033[34m\nWARN: #{msg}\033[0m"
        rescue
          warn "\nWARN: #{msg}"
        end
      end

      def _info(msg)
        begin
          puts "\033[32m\nINFO: #{msg}\033[0m"
        rescue
          puts "\nINFO: #{msg}"
        end
      end

    end
  end
end

include Calabash::Cucumber::Logging

module Calabash
  module Cucumber
    module XcodeTools

      SIM_LIB_APP_SUPPORT_DIR=File.expand_path("~/Library/Application Support/iPhone Simulator")

      # $ man xcode-select
      # DEVELOPER_DIR
      # Overrides the active developer directory. When DEVELOPER_DIR is set, its value
      # will be used instead of the system-wide active developer directory.
      def xcode_developer_dir
        # respect DEVELOPER_DIR
        return ENV['DEVELOPER_DIR'] if ENV['DEVELOPER_DIR']
        # fall back to xcode-select
        `xcode-select --print-path`.chomp
      end

      def xcode_bin_dir
        "#{xcode_developer_dir}/usr/bin"
      end

      def instruments(cmd=nil)
        instruments = "#{xcode_bin_dir}/instruments"
        return instruments if cmd == nil

        case cmd
          when :version
            # instruments, version 5.1.1 (55045)
            # noinspection RubyUnusedLocalVariable
            Open3.popen3("#{instruments}") do |stdin, stdout, stderr, wait_thr|
              stderr.read.chomp.split(' ')[2]
            end
          when :sims
            devices = `#{instruments} -s devices`.chomp.split("\n")
            devices.select { |device| device.downcase.include?('simulator') }
          else
            candidates = [:version, :sims]
            raise(ArgumentError, "expected '#{cmd}' to be one of '#{candidates}'")
        end
      end

      def instruments_supports_hyphen_s?(version=instruments(:version))
        tokens = version.split('.')
        return false if tokens[0].to_i < 5
        return false if tokens[1].to_i < 1
        true
      end

      def installed_simulators
        unless instruments_supports_hyphen_s?
          raise(RuntimeError, "instruments '#{instruments(:version)}' does not support '-s devices' arguments")
        end
        instruments(:sims)
      end

      def simulator_support_sdk_dirs
        sim_app_support_path = SIM_LIB_APP_SUPPORT_DIR
        Dir.glob("#{sim_app_support_path}/*").select { |path|
          path =~ /(\d)\.(\d)\.?(\d)?(-64)?/
        }
      end

    end
  end
end

include Calabash::Cucumber::XcodeTools

module Calabash
  module Cucumber
    module PlistBuddy

      def plist_buddy
        '/usr/libexec/PlistBuddy'
      end

      def build_plist_cmd(type, args_hash, file)

        unless File.exist?(File.expand_path(file))
          raise(RuntimeError, "plist '#{file}' does not exist - could not read")
        end

        case type
          when :add
            value_type = args_hash[:type]
            unless value_type
              raise(ArgumentError, ":value_type is a required key for :add command")
            end
            allowed_value_types = ['string', 'bool', 'real', 'integer']
            unless allowed_value_types.include?(value_type)
              raise(ArgumentError, "expected '#{value_type}' to be one of '#{allowed_value_types}'")
            end
            value = args_hash[:value]
            unless value
              raise(ArgumentError, ":value is a required key for :add command")
            end
            key = args_hash[:key]
            unless key
              raise(ArgumentError, ":key is a required key for :add command")
            end
            cmd_part = "\"Add :#{key} #{value_type} #{value}\""
          when :print
            key = args_hash[:key]
            unless key
              raise(ArgumentError, ":key is a required key for :print command")
            end
            cmd_part = "\"Print :#{key}\""
          when :set
            value = args_hash[:value]
            unless value
              raise(ArgumentError, ":value is a required key for :set command")
            end
            key = args_hash[:key]
            unless key
              raise(ArgumentError, ":key is a required key for :set command")
            end
            cmd_part = "\"Set :#{key} #{value}\""
          else
            cmds = [:add, :print, :set]
            raise(ArgumentError, "expected '#{type}' to be one of '#{cmds}'")
        end

        "#{plist_buddy} -c #{cmd_part} \"#{file}\""

      end

      def execute_plist_cmd(cmd, opts={})
        default_opts = {:verbose => false}
        merged = default_opts.merge(opts)

        _info(cmd) if merged[:verbose]

        res = nil
        # noinspection RubyUnusedLocalVariable
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          err = stderr.read
          std = stdout.read
          if not err.nil? and err != ''
            res = err.chomp
          else
            res = std.chomp
          end
        end
        res
      end

      def plist_read(key, file, opts={})
        if key.nil? or key.length == 0
          raise(ArgumentError, "key '#{key}' must not be nil or empty")
        end
        cmd = build_plist_cmd(:print, {:key => key}, file)
        res = execute_plist_cmd(cmd, opts)
        if res == "Print: Entry, \":#{key}\", Does Not Exist"
          nil
        else
          res
        end
      end

      def plist_key_exists?(symbol_or_string, file, opts={})
        plist_read(symbol_or_string, file, opts)
      end

      def plist_set(key, type, value, file, opts={})
        default_opts = {:verbose => false}
        merged = default_opts.merge(opts)

        if key.nil? or key.length == 0
          raise(ArgumentError, "key '#{key}' must not be nil or empty")
        end

        cmd_args = {:key => key,
                    :type => type,
                    :value => value}

        if plist_key_exists?(key, file, merged)
          cmd = build_plist_cmd(:set, cmd_args, file)
        else
          cmd = build_plist_cmd(:add, cmd_args, file)
        end

        res = execute_plist_cmd(cmd, merged)
        res == ''
      end

    end
  end
end

include Calabash::Cucumber::PlistBuddy

module Calabash
  module Cucumber
    module Simulator

      ACCESS_PROPERTIES_HASH =
            {
                  # this is required
                  :access_enabled => 'AccessibilityEnabled',
                  # i _think_ this is legacy
                  :app_access_enabled => 'ApplicationAccessibilityEnabled',

                  # i don't know what this does
                  :automation_enabled => 'AutomationEnabled',

                  # determines if the Accessibility Inspector is showing
                  :inspector_showing => 'AXInspectorEnabled',
                  # controls if the Accessibility Inspector is expanded or not expanded
                  :inspector_full_size => 'AXInspector.enabled',
                  # controls the frame of the Accessibility Inspector
                  # this is a 'string' => {{0, 0}, {276, 166}}
                  :inspector_frame => 'AXInspector.frame'
            }

      def kill_simulator
        dev_dir = xcode_developer_dir
        system "/usr/bin/osascript -e 'tell application \"#{dev_dir}/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app\" to quit'"
      end

      def reset_simulator_content_and_settings
        sim_lib_path = File.join(SIM_LIB_APP_SUPPORT_DIR, 'Library')
        FileUtils.rm_rf(sim_lib_path)
        simulator_support_sdk_dirs.each do |dir|
          FileUtils.rm_rf(dir)
        end
      end

      def enable_accessibility(sim_support_dir)
        kill_simulator
        plist_path = File.expand_path("#{sim_support_dir}/Library/Preferences/com.apple.Accessibility.plist")

        hash = ACCESS_PROPERTIES_HASH
        plist_set(hash[:access_enabled], 'bool', 'true', plist_path)
        plist_set(hash[:app_access_enabled], 'bool', 'true', plist_path)
        plist_set(hash[:automation_enabled], 'bool', 'true', plist_path)

        plist_set(hash[:inspector_showing], 'bool', 'false', plist_path)
        plist_set(hash[:inspector_full_size], 'bool', 'false', plist_path)
        plist_set(hash[:inspector_frame], 'string', '{{270, -13}, {276, 166}}', plist_path)
      end

    end
  end
end

include Calabash::Cucumber::Simulator

unless ARGV.empty?
  arg = ARGV.first
  unless arg == '71' or arg == 'all'
    _info('Usage:  enable_access_on_sim.rb {71 | all}')
    exit 1
  end
  if arg == '71'
    dir = File.expand_path(SIM_LIB_APP_SUPPORT_DIR)
    _info("enabling '#{dir}'")
    enable_accessibility(dir)
  else
    simulator_support_sdk_dirs.each do |dir|
      _info("enabling '#{dir}'")
      enable_accessibility(dir)
    end

  end
  exit 0
end

if __FILE__ == $0
  require 'test/unit'

  TEMPLATE_PLIST = File.expand_path('com.example.plist')
  TESTING_PLIST = File.expand_path('com.testing.plist')

  VERBOSE = {:verbose => true}
  QUIET = {:verbose => false}

  class LocalTest < Test::Unit::TestCase

    def repopulate_sim_app_support(sdk='7.1')
      kill_simulator
      `ios-sim launch EmptyAppHack.app --sdk #{sdk} --stdout /dev/null --stderr /dev/null --exit`
    end

    def repopulate_sim_app_support_all
      repopulate_sim_app_support('6.1')
      repopulate_sim_app_support('7.0')
      repopulate_sim_app_support('7.1')
    end

    # run this first
    def test_0
      repopulate_sim_app_support_all
    end

    def test_xcode_developer_dir_respects_dev_dir
      ENV['DEVELOPER_DIR'] = '/foo/bar'
      assert_equal('/foo/bar', xcode_developer_dir(),
                   'expected xcode_developer_dir to respect DEVELOPER_DIR')
    end

    def test_xcode_developer_dir
      assert_equal('/Applications/Xcode.app/Contents/Developer', xcode_developer_dir(),
                 'BRITTLE - can fail if Xcode is installed in a non-standard location')
    end

    def test_xcode_bin_dir
      assert_equal('/Applications/Xcode.app/Contents/Developer/usr/bin', xcode_bin_dir,
                   'BRITTLE - can fail if Xcode is installed in a non-standard location')

    end

    def test_instruments
      assert_equal('/Applications/Xcode.app/Contents/Developer/usr/bin/instruments', instruments,
                   'BRITTLE - can fail if Xcode is installed in a non-standard location')
    end

    def test_instruments_cmd
      assert_raise ArgumentError do
        instruments(:foo)
      end
      allowed = ['5.1.1', '5.1']
      version = instruments(:version)
      assert(allowed.include?(version),
             "expected '#{version}' to be one of '#{allowed}'")
    end

    def test_instruments_supports_hyphen_s
      assert(instruments_supports_hyphen_s?, 'BRITTLE - can fail if Xcode version is not >= 5.1')
      assert(instruments_supports_hyphen_s?('5.1.1'), 'Xcode 5.1.1 supports -s')
      assert(instruments_supports_hyphen_s?('5.1'), 'Xcode 5.1 supports -s')
      assert(!instruments_supports_hyphen_s?('5.0.2'), '5.0.2 does not support -s')
      assert(!instruments_supports_hyphen_s?('4.6.3'), '4.6.3 does not support -s')
    end

    # long running!
    def test_installed_simulators
      _warn("skipping installed simulators test")
      #sims = installed_simulators
      #assert(sims.is_a?(Array), "expected an Array, but found '#{sims.class}'")
    end

    def test_simulator_support_dirs
      in_lib = simulator_support_sdk_dirs
      assert(in_lib.is_a?(Array), "expected an Array, but '#{in_lib.class}'")
    end

    def test_plist_buddy
      assert(File.exists?(plist_buddy), 'plist buddy exe must exists')
    end

    def make_testing_plist
      FileUtils.rm(TESTING_PLIST) if File.exist?(TESTING_PLIST)
      FileUtils.cp(TEMPLATE_PLIST, TESTING_PLIST)
    end

    def test_testing_plists_exists
      assert(File.exist?(TEMPLATE_PLIST), "example plist should exist '#{TEMPLATE_PLIST}'")
      make_testing_plist
      assert(File.exist?(TESTING_PLIST), "example plist should exist '#{TESTING_PLIST}'")
    end

    def test_build_plist_cmd_no_file
      assert_raise RuntimeError do
        build_plist_cmd(:foo, nil, '/path/does/not/exist')
      end
    end

    def test_build_plist_cmd_bad_type
      make_testing_plist
      assert_raise ArgumentError do
        build_plist_cmd(:foo, nil, TESTING_PLIST)
      end
    end

    def test_build_plist_print_no_key
      make_testing_plist
      assert_raise ArgumentError do
        build_plist_cmd(:print, {:foo => 'bar'}, TESTING_PLIST)
      end
    end

    def test_build_plist_print
      make_testing_plist
      path = File.expand_path(File.join('./', 'com.testing.plist'))
      assert_equal("/usr/libexec/PlistBuddy -c \"Print :foo\" \"#{path}\"",
                   build_plist_cmd(:print, {:key => 'foo'}, TESTING_PLIST))
    end

    def test_build_plist_set
      make_testing_plist
      path = File.expand_path(File.join('./', 'com.testing.plist'))
      assert_equal("/usr/libexec/PlistBuddy -c \"Set :foo bar\" \"#{path}\"",
                   build_plist_cmd(:set, {:key => 'foo', :value => 'bar'}, TESTING_PLIST))
    end

    def test_build_plist_add
      make_testing_plist
      path = File.expand_path(File.join('./', 'com.testing.plist'))
      assert_equal("/usr/libexec/PlistBuddy -c \"Add :foo bool bar\" \"#{path}\"",
                   build_plist_cmd(:add, {:key => 'foo', :value => 'bar', :type => 'bool'}, TESTING_PLIST))
    end

    def test_plist_read_success
      make_testing_plist
      hash = ACCESS_PROPERTIES_HASH
      assert_equal('false', plist_read(hash[:inspector_showing], TESTING_PLIST, QUIET))
    end

    def test_plist_read_failure
      make_testing_plist
      assert_equal(nil, plist_read('FOO', TESTING_PLIST, QUIET))
    end

    def test_plist_set_existing
      make_testing_plist
      hash = ACCESS_PROPERTIES_HASH
      assert(plist_set(hash[:inspector_showing], 'bool', 'true', TESTING_PLIST, QUIET))
      assert_equal('true', plist_read(hash[:inspector_showing], TESTING_PLIST, QUIET))
    end

    def test_plist_create_new
      make_testing_plist
      assert(plist_set('FOO', 'bool', 'true', TESTING_PLIST, QUIET))
      assert_equal('true', plist_read('FOO', TESTING_PLIST, QUIET))
    end

    def test_enable_accessibility_71
      repopulate_sim_app_support('7.1')
      dir = File.join(SIM_LIB_APP_SUPPORT_DIR, '7.1')
      enable_accessibility(dir)
    end

    def test_enable_accessibility_61
      repopulate_sim_app_support('6.1')
      dir = File.join(SIM_LIB_APP_SUPPORT_DIR, '6.1')
      enable_accessibility(dir)
    end

    def test_reset_content_and_settings
      reset_simulator_content_and_settings
    end
  end
end
