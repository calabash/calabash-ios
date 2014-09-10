require 'calabash-cucumber/launch/simulator_launcher'
require 'calabash-cucumber/utils/simulator_accessibility'
require 'sim_launcher'
require 'calabash-cucumber/device'
require 'calabash-cucumber/actions/instruments_actions'
require 'calabash-cucumber/actions/playback_actions'
require 'run_loop'
require 'cfpropertylist'
require 'calabash-cucumber/version'
require 'calabash-cucumber/utils/logging'
require 'calabash/dylibs'

# Used to launch apps for testing in iOS Simulator or on iOS Devices.  By default
# it uses Apple's `instruments` process to launch your app, but has legacy support
# for using `sim_launcher`.
#
# ###  Accessing the current launcher from ruby.
#
# If you need a reference to the current launcher in your ruby code.
# This is usually not required, but might be useful in `support/01_launch.rb`.
#
# `Calabash::Cucumber::Launcher.launcher`
#
# ### Attaching to the current launcher in a console
#
# If Calabash already running and you want to attach to the current launcher,
# use `console_attach`.  This is useful when a cucumber Scenario has failed and
# you want to query the current state of the app.
#
# * **Pro Tip:** set the `NO_STOP` environmental variable to 1 so calabash does
#  not exit the simulator when a Scenario fails.
class Calabash::Cucumber::Launcher

  include Calabash::Cucumber::Logging
  include Calabash::Cucumber::SimulatorAccessibility

  # A hash of known privacy settings that calabash can control.
  KNOWN_PRIVACY_SETTINGS = {:photos => 'kTCCServicePhotos', :calendar => 'kTCCServiceCalendar', :address_book => 'kTCCServiceAddressBook'}

  # noinspection RubyClassVariableUsageInspection

  # @!visibility private
  @@launcher = nil

  # @!visibility private
  SERVER_VERSION_NOT_AVAILABLE = '0.0.0'
  # noinspection RubyClassVariableUsageInspection

  # @!visibility private
  # Class variable for caching the embedded server version so we only need to
  # check the server version one time.
  @@server_version = nil

  attr_accessor :run_loop
  attr_accessor :device
  attr_accessor :actions
  attr_accessor :launch_args
  attr_accessor :simulator_launcher

  # @!visibility private
  # Generated when calabash cannot launch the app.
  class StartError < RuntimeError
    attr_accessor :error

    def initialize(err)
      self.error= err
    end

    # @!visibility private
    def to_s
      "#{super.to_s}: #{error}"
    end
  end

  # @!visibility private
  # Generated when calabash cannot communicate with the app.
  class CalabashLauncherTimeoutErr < Timeout::Error
  end

  # @!visibility private
  def initialize
    @simulator_launcher = Calabash::Cucumber::SimulatorLauncher.new
    @@launcher = self
  end

  # @!visibility private
  def actions
    attach if @actions.nil?
    @actions
  end

  # @see Calabash::Cucumber::Core#console_attach
  def self.attach
    l = launcher
    return l if l && l.active?
    l.attach
  end

  # @see Calabash::Cucumber::Core#console_attach
  def attach(max_retry=1, timeout=10)
    if calabash_no_launch?
      self.actions= Calabash::Cucumber::PlaybackActions.new
      return
    end

    pids_str = `ps x -o pid,command | grep -v grep | grep "instruments" | awk '{printf "%s,", $1}'`
    pids = pids_str.split(',').map { |pid| pid.to_i }
    pid = pids.first
    rl = {}
    if pid
      rl[:pid] = pid
      self.actions= Calabash::Cucumber::InstrumentsActions.new
    else
      self.actions= Calabash::Cucumber::PlaybackActions.new
    end

    self.run_loop= rl

    ensure_connectivity(max_retry, timeout)

    major = self.device.ios_major_version
    if major.to_i >= 7 && self.actions.is_a?(Calabash::Cucumber::PlaybackActions)
      puts "\n\n WARNING \n\n"
      puts 'Warning Trying to connect to simulator that was not launched by Calabash/instruments.'
      puts 'To fix this you must let Calabash or instruments launch the app'
      puts 'Continuing... query et al will work.'
      puts "\n\n WARNING \n\n"
      puts "Please read: https://github.com/calabash/calabash-ios/wiki/A0-UIAutomation---instruments-problems"
    end


    self
  end

  # Are we running using instruments?
  #
  # @return {Boolean} true if we're using instruments to launch
  def self.instruments?
    l = launcher_if_used
    return false unless l
    l.instruments?
  end

  # Get a reference to the current launcher (instantiates a new one if needed). Usually we use a singleton launcher throughout a test run.
  # @return {Calabash::Cucumber::Launcher} the current launcher
  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
  end

  # Get a reference to the current launcher (does not instantiate a new one if unset).
  # Usually we use a singleton launcher throughout a test run.
  # @return {Calabash::Cucumber::Launcher} the current launcher or nil
  def self.launcher_if_used
    @@launcher
  end

  # "Major" component of the current iOS version of the device
  # @return {String} the "major" component, e.g., "7" for "7.1.1"
  def ios_major_version
    # pinging the app will set self.device
    ping_app if self.device.nil?
    # guard against Runtime errors
    return nil if device.nil? or device.ios_version.nil?
    device.ios_major_version
  end

  # the current iOS version of the device
  # @return {String} the current iOS version of the device
  def ios_version
    return nil if device.nil?
    device.ios_version
  end

  # @deprecated 0.10.0 Replaced with {#reset_app_sandbox}.
  # Reset the app sandbox for a device.
  def reset_app_jail(sdk=nil, path=nil)
    # will be deprecated in a future version
    #_deprecated('0.10.0', 'use reset_app_sandbox instead', :warn)
    reset_app_sandbox({:sdk => sdk, :path => path})
  end

  # Resets the app's content and settings by deleting the following directories
  # from application sandbox:
  #
  # * Library
  # * Documents
  # * tmp
  #
  # @note It is not recommended that you call this method directly.  See the
  #  examples below for how use the `RESET_BETWEEN_SCENARIOS` environmental
  #  variable to reset the app sandbox.
  #
  # @note This method is only available for the iOS Simulator.
  #
  # @note Generates a warning if called when targeting a physical device and
  #  otherwise has no effect.
  #
  # @note When testing against the Xamarin Test Cloud, this method is never
  #  called.  Use the `RESET_BETWEEN_SCENARIOS` environmental variable.
  #  See the examples.
  #
  # @example Use `RESET_BETWEEN_SCENARIOS` to reset the app sandbox before every Scenario.
  #  When testing devices outside the Xamarin Test Cloud this has no effect.
  #
  #  On the Xamarin Test Cloud, the app sandbox will be reset, but this method
  #  will not be called; the resetting is done via an alternative mechanism.
  #
  #  When testing simulators, this method will be called.
  #
  #  Launch cucumber with RESET_BETWEEN_SCENARIOS=1
  #
  #  $ RESET_BETWEEN_SCENARIOS=1 bundle exec cucumber
  #
  # @example Use tags and a Before hook to reset the app sandbox before specific Scenarios.
  #  # in your .feature file
  #
  #  @reset_app_before_hook
  #  Scenario:  some scenario that requires the app be reset
  #
  #  # in your support/01_launch.rb file
  #  #
  #  # 1. add a Before hook
  #  Before('@reset_app_before_hook') do
  #    ENV['RESET_BETWEEN_SCENARIOS'] = '1'
  #  end
  #
  #  # 2. after launching, revert the env var value
  #  Before do |scenario|
  #    # launch the app
  #    launcher = Calabash::Cucumber::Launcher.new
  #    unless launcher.calabash_no_launch?
  #      launcher.relaunch
  #      launcher.calabash_notify(self)
  #    end
  #    # disable resetting between Scenarios
  #    ENV['RESET_BETWEEN_SCENARIOS'] = ''
  #  end
  #
  # @param [Hash] opts can pass the target sdk or the path to the application bundle
  # @option opts [String, Symbol] :sdk (nil) The target sdk.  If nil is
  #  passed, then only app sandbox for the latest sdk will be deleted.  If
  #  `:all` is passed, then the sandboxes for all sdks will be deleted.
  # @option opts [String] :path (nil) path to the application bundle
  def reset_app_sandbox(opts={})

    if device_target?
      calabash_warn("calling 'reset_app_sandbox' when targeting a device.")
      return
    end

    default_opts = {:sdk => nil, :path => nil}
    merged_opts = default_opts.merge opts

    sdk ||= merged_opts[:sdk] || sdk_version || self.simulator_launcher.sdk_detector.latest_sdk_version
    path ||= merged_opts[:path] || self.simulator_launcher.app_bundle_or_raise(app_path)

    app = File.basename(path)

    directories_for_sdk_prefix(sdk).each do |sdk_dir|
      app_dir = File.expand_path("#{sdk_dir}/Applications")
      next unless File.exists?(app_dir)

      bundle = `find "#{app_dir}" -type d -depth 2 -name "#{app}" | head -n 1`

      next if bundle.empty? # Assuming we're already clean

      if debug_logging?
        puts "Reset app state for #{bundle}"
      end
      sandbox = File.dirname(bundle)
      ['Library', 'Documents', 'tmp'].each do |content_dir|
        FileUtils.rm_rf(File.join(sandbox, content_dir))
      end
    end
  end

  # Simulates touching the iOS Simulator > Reset Content and Settings... menu
  # item.
  #
  # @note
  #  **WARNING** This is a destructive operation.  You have been warned.
  #
  # @raise RuntimeError if called when targeting a physical device
  def reset_simulator
    if device_target?
      raise "calling 'reset_simulator' when targeting a device is not allowed"
    end
    reset_simulator_content_and_settings
  end

  # @!visibility private
  def directories_for_sdk_prefix(sdk)
    if sdk == :all
      existing_simulator_support_sdk_dirs
    else
      Dir["#{simulator_app_support_dir}/#{sdk}*"]
    end
  end

  # Call as `update_privacy_settings('com.my.app', {:photos => {:allow => true}})`
  # @!visibility private
  def update_privacy_settings(bundle_id, opts={})
    if debug_logging?
      puts "Update privacy settings #{bundle_id}, #{opts}"
    end
    unless File.exist?(`which sqlite3`.strip)
      raise 'Error: Unable to find sqlite3. The binary sqlite3 must be installed and on path.'
    end
    opts.each do |setting_name, setting_options|

      setting_name = KNOWN_PRIVACY_SETTINGS[setting_name] || setting_name
      allow = setting_options[:allow] == false ? false : true
      sdk = setting_options[:sdk] || self.simulator_launcher.sdk_detector.latest_sdk_version

      dirs = directories_for_sdk_prefix(sdk)
      if debug_logging?
        puts "About to update privacy setting #{setting_name} for #{bundle_id}, allow: #{allow} in sdk #{sdk}, #{dirs}"
      end

      dirs.each do |dir|
        if debug_logging?
          puts "Setting access for #{bundle_id} for permission #{setting_name} to allow: #{allow}"
        end
        path_to_tcc_db = tcc_database_for_sdk_dir(dir)
        unless File.exist?(path_to_tcc_db)
          puts "Warning: No TCC.db in location #{path_to_tcc_db}"
          next
        end
        allowed_as_i = allow ? 1 : 0
        if privacy_setting(dir, bundle_id,setting_name).nil?
          sql = %Q['INSERT INTO access (service, client, client_type, allowed, prompt_count) VALUES ("#{setting_name}","#{bundle_id}",0,#{allowed_as_i},1);']
        else
          sql = %Q['UPDATE access SET allowed=#{allowed_as_i} where client="#{bundle_id}" AND service="#{setting_name}";']
        end

        if debug_logging?
          puts "Executing sql #{sql} on #{path_to_tcc_db}"
        end

        unless system(%Q[sqlite3 "#{path_to_tcc_db}" #{sql}]) && privacy_setting(dir,bundle_id,setting_name) == allowed_as_i
          puts "Warning: Error executing sql: #{sql} against #{path_to_tcc_db} (Setting is #{privacy_setting(dir,bundle_id,setting_name)}). Continuing..."
          next
        end
      end
    end
  end

  # @!visibility private
  def tcc_database_for_sdk_dir(dir)
    File.join(dir,'Library', 'TCC', 'TCC.db')
  end

  # @!visibility private
  def privacy_setting(sdk_dir, bundle_id, setting_name)
    setting_name = KNOWN_PRIVACY_SETTINGS[setting_name] || setting_name
    path_to_tcc_db = tcc_database_for_sdk_dir(sdk_dir)
    sql = %Q['SELECT allowed FROM access WHERE client="#{bundle_id}" and service="#{setting_name}";']
    output = `sqlite3 "#{path_to_tcc_db}" #{sql}`.strip

    (output == '0' || output == '1') ? output.to_i : nil
  end

  # @!visibility private
  def default_launch_args
    # APP_BUNDLE_PATH
    # BUNDLE_ID
    # APP (unifies APP_BUNDLE_PATH, BUNDLE_ID)
    # DEVICE_TARGET
    # SDK_VERSION
    # RESET_BETWEEN_SCENARIOS
    # DEVICE
    # NO_LAUNCH
    # NO_STOP

    args = {
        :launch_method => default_launch_method,
        :reset => reset_between_scenarios?,
        :bundle_id => ENV['BUNDLE_ID'],
        :device => device_env,
        :no_stop => calabash_no_stop?,
        :no_launch => calabash_no_launch?,
        :sdk_version => sdk_version,
        # Do not advertise this to users!
        # For example, don't include documentation about this option.
        # This is used to instrument internal testing (failing fast).
        :launch_retries => 5
    }

    device_tgt = ENV['DEVICE_TARGET']
    if run_with_instruments?(args)
      if simulator_target?
        args[:device_target] = device_tgt
        args[:udid] = nil
      else
        if detect_connected_device? && (device_tgt.nil? || device_tgt.downcase == 'device')
          device_tgt = RunLoop::Core.detect_connected_device
        end

        if device_tgt
          args[:device_target] = args[:udid] = device_tgt
        end
      end
    end

    if args[:device_target].nil?
      args[:device_target] = device_tgt || 'simulator'
    end
    args
  end

  # @!visibility private
  def detect_connected_device?
    if ENV['DETECT_CONNECTED_DEVICE'] == '1'
      return true
    end

    if ENV['BUNDLE_ID'].nil? && ENV['DETECT_CONNECTED_DEVICE'].nil?
      return false
    end
    if ENV['BUNDLE_ID'] && ENV['DETECT_CONNECTED_DEVICE'].nil?
      return true
    end
    if ENV['DETECT_CONNECTED_DEVICE']
      return ENV['DETECT_CONNECTED_DEVICE'] != '0'
    end

    return false
  end

  # @!visibility private
  def default_launch_method
    sdk = sdk_version
    major = nil
    if sdk && !sdk.strip.empty?
      major = sdk.split('.')[0]
      begin
        major = major.to_i
      rescue
        calabash_warn("SDK_VERSION invalid #{sdk_version} - ignoring...")
      end
    end
    return :instruments if major && major >= 7 # Only instruments supported for iOS7+
    return :sim_launcher if major # and then we have <= 6

    if RunLoop::XCTools.new.xcode_version_gte_51?
      return use_sim_launcher_env? ? :sim_launcher : :instruments
    end

    available = self.simulator_launcher.sdk_detector.available_sdk_versions.reject { |v| v.start_with?('7') }
    if available.include?(sdk_version)
      :sim_launcher
    else
      :instruments
    end
  end

  # Launches your app on the connected device or simulator. Stops the app if it is already running.
  # `relaunch` does a lot of error detection and handling to reliably start the app and test. Instruments (particularly the cli)
  # has stability issues which we workaround by restarting the simulator process and checking that UIAutomation is correctly
  # attaching.
  #
  # Takes optional args to specify details of the launch (e.g. device or simulator, sdk version, target device, launch method...).
  # @note an important part of relaunch behavior is controlled by environment variables, specified below
  #
  # The two most important environment variables are `DEVICE_TARGET` and `APP_BUNDLE_PATH`.
  #
  # - `DEVICE_TARGET` controls which device you're running on. To see the options run: `instruments -s devices`.
  #   In addition you can specify `DEVICE_TARGET=device` to run on a (unique) usb-connected device.
  # - `APP_BUNDLE_PATH` controls which `.app` bundle to launch in simulator (don't use for on-device testing, instead use `BUNDLE_ID`).
  # - `BUNDLE_ID` used with `DEVICE_TARGET=device` to specify which app to launch on device
  # - `DEBUG` - set to "1" to obtain debug info (typically used to debug launching, UIAutomation and other issues)
  # - `DEBUG_HTTP` - set to "1" to show raw HTTP traffic
  #
  #
  # @example Launching on iPad simulator with DEBUG settings
  #   DEBUG_HTTP=1 DEVICE_TARGET="iPad - Simulator - iOS 7.1" DEBUG=1 APP_BUNDLE_PATH=FieldServiceiOS.app bundle exec calabash-ios console
  # @param {Hash} args optional args to specify details of the launch (e.g. device or simulator, sdk version,
  #   target device, launch method...).
  # @option args {String} :app (detect the location of the bundle from project settings) app bundle path
  # @option args {String} :bundle_id if launching on device, specify this or env `BUNDLE_ID` to be the bundle identifier
  #   of the application to launch
  # @option args {Hash} :privacy_settings preset privacy settings for the, e.g., `{:photos => {:allow => true}}`.
  #    See {KNOWN_PRIVACY_SETTINGS}
  def relaunch(args={})
    #TODO stopping is currently broken, but this works anyway because instruments stop the process before relaunching
    RunLoop.stop(run_loop) if run_loop

    args = default_launch_args.merge(args)

    args[:app] = args[:app] || args[:bundle_id] || app_path || detect_app_bundle_from_args(args)


    if args[:app]
      if File.directory?(args[:app])
        args[:app] = File.expand_path(args[:app])
      else
        # args[:app] is not a directory so must be a bundle id
        if simulator_target?(args) ## bundle id set, but simulator target
          args[:app] = app_path || detect_app_bundle_from_args(args)
        end
      end
    end

    unless args[:app]
      if simulator_target?(args)
        device_xamarin_build_dir = 'iPhoneSimulator'
      else
        device_xamarin_build_dir = 'iPhone'
      end
      args[:app] = self.simulator_launcher.app_bundle_or_raise(app_path, device_xamarin_build_dir)
    end

    args[:bundle_id] ||= detect_bundle_id_from_app_bundle(args)

    args[:device] ||= detect_device_from_args(args)

    if simulator_target?(args) and args[:reset]
      # attempt to find the sdk version from the :device_target
      sdk = sdk_version_for_simulator_target(args)

      # *** LEGACY SUPPORT ***
      # If DEVICE_TARGET has not been set and is not a device UDID, then
      # :device_target will be 'simulator'.  In that case, we cannot know what
      # SDK version of the app sandbox we should reset.  The user _might_ give
      # us a hint with SDK_VERSION, but we want to deprecate that variable ASAP.
      #
      # If passed a nil SDK arg, reset_app_sandbox will reset the _latest_ SDK.
      # This is not good, because this is probably _not_ the SDK that should be
      # reset.  Our only option is to reset every sandbox for all SDKs by
      # passing :sdk => :all to reset_app_sandbox.
      if sdk.nil? and args[:device_target] == 'simulator'
        sdk = :all
      end
      reset_app_sandbox({:sdk => sdk, :path => args[:app]})
    end

    if args[:privacy_settings]
      if simulator_target?(args)
        update_privacy_settings(args[:bundle_id], args[:privacy_settings])
      else
        #Not supported on device
        puts 'Warning: :privacy_settings not supported on device'
      end
    end

    # The public API is true/false, but we need to pass a path to a dylib to
    # run-loop.
    if args.fetch(:inject_dylib, false)
      if simulator_target?(args)
        args[:inject_dylib] = Calabash::Dylibs.path_to_sim_dylib
      else
        args[:inject_dylib] = Cucumber::Dylibs.path_to_device_dylib
      end
    end

    if run_with_instruments?(args)
      # Patch for bug in Xcode 6 GM + iOS 8 device testing.
      # http://openradar.appspot.com/radar?id=5891145586442240
      #
      # RunLoop::Core.run_with_options can reuse the SimControl instance.  Many
      # of the Xcode tool calls, like instruments -s templates, take a long time
      # to execute.  The SimControl instance has XCTool attribute which caches
      # the results of many of these time-consuming calls so they only need to
      # be called 1 time per launch.
      # @todo Use SimControl in Launcher in place of methods like simulator_target?
      args[:sim_control] = RunLoop::SimControl.new
      uia_strategy = default_uia_strategy(args, args[:sim_control])
      args[:uia_strategy] ||= uia_strategy
      calabash_info "Using uia strategy: '#{args[:uia_strategy]}'" if debug_logging?

      self.run_loop = new_run_loop(args)
      self.actions= Calabash::Cucumber::InstrumentsActions.new
    else
      # run with sim launcher
      self.actions= Calabash::Cucumber::PlaybackActions.new
      # why not just pass args - AFAICT args[:app] == app_path?
      self.simulator_launcher.relaunch(app_path, sdk_version(), args)
    end
    self.launch_args = args

    unless args[:calabash_lite]
      ensure_connectivity
      # skip compatibility check if injecting dylib
      unless args.fetch(:inject_dylib, false)
        check_server_gem_compatibility
      end
    end
  end

  # @!visibility private
  #
  # Choose the appropriate default UIA strategy based on the test target.
  #
  # This is a temporary (I hope) fix for a UIAApplication bug in
  # setPreferencesValueForKey on iOS 8 devices in Xcode 6 GM.
  #
  # rdar://18296714
  # http://openradar.appspot.com/radar?id=5891145586442240
  def default_uia_strategy(launch_args, sim_control)
    # Preferences strategy works on Xcode iOS Simulators.
    if RunLoop::Core.simulator_target?(launch_args, sim_control)
      :preferences
    else
      target_udid = launch_args[:device_target]
      target_device = nil
      sim_control.xctools.instruments(:devices).each do |device|
        if device.udid == target_udid
          target_device = device
          break
        end
      end
      # Preferences strategy works for iOS < 8.0, but not for iOS >= 8.0.
      if target_device.version < RunLoop::Version.new('8.0')
        :preferences
      else
        :host
      end
    end
  end

  # @!visibility private
  def detect_device_from_args(args)
    if args[:app] && File.directory?(args[:app])
      # Derive bundle id from bundle_dir
      plist_as_hash = info_plist_from_bundle_path(args[:app])
      if plist_as_hash
        device_family = plist_as_hash['UIDeviceFamily']
        if device_family
          first_device = device_family.first
          if first_device == 2
            return 'ipad'
          else
            return 'iphone'
          end
        end
      end
    else
      args[:app]
    end
  end

  # @!visibility private
  def detect_app_bundle_from_args(args)
    if simulator_target?(args)
      device_xamarin_build_dir = 'iPhoneSimulator'
    else
      device_xamarin_build_dir = 'iPhone'
    end
    # is this really only applicable to the Xamarin IDE?
    self.simulator_launcher.detect_app_bundle(nil, device_xamarin_build_dir)
  end

  # @!visibility private
  def detect_bundle_id_from_app_bundle(args)
    if args[:app] && File.directory?(args[:app])
      # Derive bundle id from bundle_dir
      plist_as_hash = info_plist_from_bundle_path(args[:app])
      if plist_as_hash
        plist_as_hash['CFBundleIdentifier']
      end
    else
      args[:app]
    end
  end

  # @!visibility private
  def info_plist_from_bundle_path(bundle_path)
    plist_path = File.join(bundle_path, 'Info.plist')
    info_plist_as_hash(plist_path) if File.exist?(plist_path)
  end

  # @!visibility private
  def new_run_loop(args)

    # for stability, quit the simulator if Xcode version is > 5.1 and the
    # target device is the simulator
    target_is_sim = simulator_target?(args)
    if target_is_sim and RunLoop::XCTools.new.xcode_version_gte_51?
      self.simulator_launcher.stop
    end

    last_err = nil

    num_retries = args[:launch_retries] || 5

    num_retries.times do
      begin
        return RunLoop.run(args)
      rescue RunLoop::TimeoutError => e
        last_err = e
        if full_console_logging?
          puts 'retrying run loop...'
        end
        self.simulator_launcher.stop
      end
    end
    self.simulator_launcher.stop
    puts "Unable to start. Make sure you've set APP_BUNDLE_PATH to a build supported by this simulator version"
    raise StartError.new(last_err)
  end

  # @!visibility private
  def ensure_connectivity(max_retry=10, timeout=30)
    begin
      max_retry_count = (ENV['MAX_CONNECT_RETRY'] || max_retry).to_i
      timeout = (ENV['CONNECT_TIMEOUT'] || timeout).to_i
      retry_count = 0
      connected = false
      if full_console_logging?
        puts 'Waiting for App to be ready'
      end
      until connected do
        if retry_count == max_retry_count
          raise "Timed out connecting to Calabash server after #{max_retry_count} retries. Make sure it is linked and App isn't crashing"
        end
        retry_count += 1
        begin
          Timeout::timeout(timeout, CalabashLauncherTimeoutErr) do
            until connected
              begin
                connected = (ping_app == '200')
                break if connected
              rescue Exception => e
                #p e
                #retry
              ensure
                sleep 1 unless connected
              end
            end
          end
        rescue CalabashLauncherTimeoutErr => e
          if full_console_logging?
            puts "Timed out after #{timeout} secs, trying to connect to Calabash server..."
            puts "Will retry #{max_retry_count - retry_count}"
          end
        end
      end
    rescue RuntimeError => e
      p e
      msg = "Unable to make connection to Calabash Server at #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}\n"
      msg << "Make sure you don't have a firewall blocking traffic to #{ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/"}.\n"
      raise msg
    end
  end

  # @!visibility private
  def ping_app
    url = URI.parse(ENV['DEVICE_ENDPOINT']|| "http://localhost:37265/")

    http = Net::HTTP.new(url.host, url.port)
    res = http.start do |sess|
      sess.request Net::HTTP::Get.new(ENV['CALABASH_VERSION_PATH'] || "version")
    end
    status = res.code
    begin
      http.finish if http and http.started?
    rescue Exception => e

    end

    if status == '200'
      version_body = JSON.parse(res.body)
      self.device = Calabash::Cucumber::Device.new(url, version_body)
    end

    status
  end

  # @!visibility private
  def stop
    RunLoop.stop(run_loop) if run_loop && run_loop[:pid]
  end

  # @!visibility private
  def calabash_notify(world)
    if world.respond_to?(:on_launch)
      world.on_launch
    end
  end

  # @!visibility private
  def info_plist_as_hash(plist_path)
    unless File.exist?(plist_path)
      raise "Unable to find Info.plist: #{plist_path}"
    end
    parsedplist = CFPropertyList::List.new(:file => plist_path)
    CFPropertyList.native_types(parsedplist.value)
  end

  # @!visibility private
  def detect_bundle_id
    begin
      bundle_path = self.simulator_launcher.app_bundle_or_raise(app_path)
      plist_path = File.join(bundle_path, 'Info.plist')
      info_plist_as_hash(plist_path)['CFBundleIdentifier']
    rescue => e
      raise "Unable to automatically find bundle id. Please set BUNDLE_ID environment variable. #{e}"
    end
  end

  # @!visibility private
  def calabash_no_stop?
    calabash_no_launch? or ENV['NO_STOP']=="1"
  end

  # @!visibility private
  def calabash_no_launch?
    ENV['NO_LAUNCH']=='1'
  end

  # @!visibility private
  def device_target?
    (ENV['DEVICE_TARGET'] != nil) && (not simulator_target?)
  end

  # @!visibility private
  def simulator_target?(launch_args={})
    value = ENV['DEVICE_TARGET'] || launch_args[:device_target]
    return false if value.nil?
    value.downcase.include?('simulator')
  end

  # @!visibility private
  def sdk_version
    ENV['SDK_VERSION']
  end

  # @!visibility private
  def sdk_version_for_simulator_target(launch_args)
    return nil if device_target?
    value = launch_args[:device_target]
    return nil if value.nil?
    return nil unless value.downcase.include?('simulator')
    # we have a string like:
    # iPhone Retina (4-inch) - Simulator - iOS 7.1
    # iPad Retina - Simulator - iOS 6.1
    # iPhone Retina (4-inch 64-bit) - Simulator - iOS 7.0
    sdk = value.split(' ').last

    # legacy support for DEVICE_TARGET=simulator
    return nil if sdk == 'simulator'
    sdk
  end

  # @!visibility private
  def use_instruments_env?
    ENV['LAUNCH_VIA'] == 'instruments'
  end

  # @!visibility private
  def use_sim_launcher_env?
    ENV['LAUNCH_VIA'] == 'sim_launcher'
  end

  # @!visibility private
  def reset_between_scenarios?
    ENV['RESET_BETWEEN_SCENARIOS']=="1"
  end

  # @!visibility private
  def device_env
    ENV['DEVICE']
  end

  # @!visibility private
  def app_path
    ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH) || ENV['APP']
  end

  # @!visibility private
  def run_with_instruments?(args)
    args && args[:launch_method] == :instruments
  end

  # @!visibility private
  def active?
    not run_loop.nil?
  end

  # @!visibility private
  def instruments?
    !!(active? && run_loop[:pid])
  end

  # @!visibility private
  def inspect
    msg = ["#{self.class}: Launch Method #{launch_args && launch_args[:launch_method]}"]
    if run_with_instruments?(self.launch_args) && self.run_loop
      msg << "Log file: #{self.run_loop[:log_file]}"
    end
    msg.join("\n")
  end

  # @!visibility private
  # Extracts server version from the app binary at `app_bundle_path` by
  # inspecting the binary's strings table.
  #
  # @note
  #  SPECIAL: sets the `@@server_version` class variable to cache the server
  #  version because the server version will never change during runtime.
  #
  # @return [String] the server version
  # @param [String] app_bundle_path file path (usually) to the application bundle
  # @raise [RuntimeError] if there is no executable at `app_bundle_path`
  # @raise [RuntimeError] if the server version cannot be extracted from any
  #   binary at `app_bundle_path`
  def server_version_from_bundle(app_bundle_path)
    return @@server_version unless @@server_version.nil?
    exe_paths = []
    Dir.foreach(app_bundle_path) do |item|
      next if item == '.' or item == '..'

      full_path = File.join(app_bundle_path, item)
      if File.executable?(full_path) and not File.directory?(full_path)
        exe_paths << full_path
      end
    end

    if exe_paths.empty?
      calabash_warn "could not find executable in '#{app_bundle_path}'"

      @@server_version = SERVER_VERSION_NOT_AVAILABLE
      return @@server_version
    end

    server_version = nil
    exe_paths.each do |path|
      server_version_string = `strings "#{path}" | grep -E 'CALABASH VERSION'`.chomp!
      if server_version_string
        server_version = server_version_string.split(' ').last
        break
      end
    end

    unless server_version
      calabash_warn('could not find server version by inspecting the binary strings table')

      @@server_version = SERVER_VERSION_NOT_AVAILABLE
      return @@server_version
    end

    @@server_version = server_version
  end

  # queries the server for its version.
  #
  # SPECIAL: sets the +@@server_version+ class variable to cache the server
  # version because the server version will never change during runtime.
  #
  # @return [String] the server version
  # @raise [RuntimeError] if the server cannot be reached
  def server_version_from_server
    return @@server_version unless @@server_version.nil?
    ensure_connectivity if self.device == nil
    @@server_version = self.device.server_version
  end

  # checks the server and gem version compatibility and generates a warning if
  # the server and gem are not compatible.
  #
  # WIP:  this is a proof-of-concept implementation and requires _strict_
  # equality.  in the future we should allow minimum framework compatibility.
  #
  # @!visibility private
  # @return [nil] nothing to return
  def check_server_gem_compatibility
    app_bundle_path = self.launch_args[:app]
    if File.directory?(app_bundle_path)
      server_version = server_version_from_bundle(app_bundle_path)
    else
      server_version = server_version_from_server
    end

    if server_version == SERVER_VERSION_NOT_AVAILABLE
      calabash_warn('server version could not be found - skipping compatibility check')
      return nil
    end

    server_version = Calabash::Cucumber::Version.new(server_version)
    gem_version = Calabash::Cucumber::Version.new(Calabash::Cucumber::VERSION)
    min_server_version = Calabash::Cucumber::Version.new(Calabash::Cucumber::MIN_SERVER_VERSION)

    if server_version < min_server_version
      msgs = []
      msgs << 'server version is not compatible with gem version'
      msgs << 'please update your server and gem'
      msgs << "       gem version: '#{gem_version}'"
      msgs << "min server version: '#{min_server_version}'"
      msgs << "    server version: '#{server_version}'"

      calabash_warn("#{msgs.join("\n")}")
    else
      if full_console_logging?
        calabash_info("gem #{gem_version} is compat with '#{server_version}'")
      end
    end
    nil
  end

end
