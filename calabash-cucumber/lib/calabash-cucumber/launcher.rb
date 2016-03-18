require 'calabash-cucumber/device'
require 'calabash-cucumber/actions/instruments_actions'
require 'run_loop'
require 'cfpropertylist'
require 'calabash-cucumber/utils/logging'
require "calabash-cucumber/usage_tracker"

# Used to launch apps for testing in iOS Simulator or on iOS Devices.
#
# ###  Accessing the current launcher from ruby.
#
# If you need a reference to the current launcher in your ruby code.
#
# `Calabash::Cucumber::Launcher.launcher`
#
# This is usually not required, but might be useful in `support/01_launch.rb`.
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

  require "calabash-cucumber/dylibs"
  require "calabash-cucumber/environment"

  include Calabash::Cucumber::Logging

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
  @@launcher = nil

  # @!visibility private
  SERVER_VERSION_NOT_AVAILABLE = '0.0.0'

  # @!visibility private
  # Class variable for caching the embedded server version so we only need to
  # check the server version one time.
  @@server_version = nil

  # @!visibility private
  attr_accessor :run_loop

  # @!visibility private
  attr_accessor :device

  # @!visibility private
  attr_accessor :actions

  # @!visibility private
  attr_accessor :launch_args

  # @!visibility private
  attr_reader :xcode

  # @!visibility private
  attr_reader :usage_tracker

  # @!visibility private
  attr_reader :device_endpoint

  # @!visibility private
  def initialize
    @@launcher = self
  end

  # @!visibility private
  def to_s
    msg = ["#{self.class}"]
    if self.run_loop
      msg << "Log file: #{self.run_loop[:log_file]}"
    else
      msg << "Not attached to instruments."
      msg << "Start your app with `start_test_server_in_background`"
      msg << "If you app is already running, try `console_attach`"
    end
    msg.join("\n")
  end

  # @!visibility private
  def inspect
    to_s
  end

  # @!visibility private
  def xcode
    @xcode ||= RunLoop::Xcode.new
  end

  # @!visibility private
  def usage_tracker
    @usage_tracker ||= Calabash::Cucumber::UsageTracker.new
  end

  # @!visibility private
  def device_endpoint
    @device_endpoint ||= Calabash::Cucumber::Environment.device_endpoint
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
  def attach(options={})
    default_options = {:http_connection_retry => 1,
                       :http_connection_timeout => 10}
    merged_options = default_options.merge(options)

    self.run_loop = RunLoop::HostCache.default.read

    # Sets this Launcher#device attribute.
    ensure_connectivity(merged_options)

    if self.run_loop[:pid]
      self.actions = Calabash::Cucumber::InstrumentsActions.new
    else
      calabash_warn(%Q{

WARNING

Connected to simulator that was not launched by Calabash.

Queries will work, but gestures will not.

})
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

  # @!visibility private
  def instruments?
    !!(active? && run_loop[:pid])
  end

  # @!visibility private
  def active?
    not run_loop.nil?
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

  # Erases a simulator. This is the same as touching the Simulator
  # "Reset Content & Settings" menu item.
  #
  # @param [RunLoop::Device, String] device The simulator to erase.  Can be a
  #  RunLoop::Device instance, a simulator UUID, or a human readable simulator
  #  name.
  #
  # @raise ArgumentError If the simulator is a physical device
  # @raise RuntimeError If the simulator cannot be shutdown
  # @raise RuntimeError If the simulator cannot be erased
  def reset_simulator(device=nil)
    if device_target?
      raise ArgumentError, "Resetting physical devices is not supported."
    end

    simulator = nil

    if device.nil? || device == ""
      device_target = Calabash::Cucumber::Environment.device_target
      if device_target.nil?
        default_simulator = RunLoop::Core.default_simulator
        simulator = RunLoop::Device.device_with_identifier(default_simulator)
      else
        simulator = RunLoop::Device.device_with_identifier(device_target)
      end
    elsif device.is_a?(RunLoop::Device)
      if device.physical_device?
        raise ArgumentError,
%Q{
Cannot reset: #{device}.

Resetting physical devices is not supported.
}
      end
      simulator = device
    else
      simulator = RunLoop::Device.device_with_identifier(device)
    end

    RunLoop::CoreSimulator.erase(simulator)
    simulator
  end

  # @!visibility private
  def default_launch_args
    # APP_BUNDLE_PATH
    # BUNDLE_ID
    # APP (unifies APP_BUNDLE_PATH, BUNDLE_ID)
    # DEVICE_TARGET
    # RESET_BETWEEN_SCENARIOS
    # DEVICE
    # NO_STOP

    args = {
        :reset => Calabash::Cucumber::Environment.reset_between_scenarios?,
        :bundle_id => ENV['BUNDLE_ID'],
        :no_stop => calabash_no_stop?,
        :relaunch_simulator => true,
        # Do not advertise this to users!
        # For example, don't include documentation about this option.
        # This is used to instrument internal testing (failing fast).
        :launch_retries => 5
    }

    device_tgt = ENV['DEVICE_TARGET']
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

  # Launches your app on the connected device or simulator.
  #
  # `relaunch` does a lot of error detection and handling to reliably start the
  # app and test. Instruments (particularly the cli) has stability issues which
  # we workaround by restarting the simulator process and checking that
  # UIAutomation is correctly attaching to your application.
  #
  # Use the `args` parameter to to control:
  #
  # * `:app` - which app to launch.
  # * `:device_target` - simulator or device to target.
  # * `:reset_app_sandbox - reset he app's data (sandbox) before testing
  #
  # and many other behaviors.
  #
  # Many of these behaviors can be be controlled by environment variables. The
  # most important environment variables are `APP`, `DEVICE_TARGET`, and
  # `DEVICE_ENDPOINT`.
  #
  # @param {Hash} args optional arguments to control the how the app is launched
  def relaunch(args={})

    # @todo Don't overwrite the _args_ parameter!
    args = default_launch_args.merge(args)

    # RunLoop::Core.run_with_options can reuse the SimControl instance.  Many
    # of the Xcode tool calls, like instruments -s templates, take a long time
    # to execute.
    # @todo Use SimControl in Launcher in place of methods like simulator_target?
    args[:sim_control] = RunLoop::SimControl.new
    args[:instruments] = RunLoop::Instruments.new
    args[:xcode] = xcode

    if args[:app]
      if !File.exist?(args[:app])
        raise "Unable to find app bundle at #{args[:app]}. It should be an iOS Simulator build (typically a *.app directory)."
      end
    end

    # User passed {:app => "path/to/my.app"} _and_ it exists.
    # User defined BUNDLE_ID or passed {:bundle_id => com.example.myapp}
    # User defined APP or APP_BUNDLE_PATH env vars _or_ APP_BUNDLE_PATH constant.
    args[:app] = args[:app] || args[:bundle_id] || app_path

    if args[:app]
      if File.directory?(args[:app])
        args[:app] = File.expand_path(args[:app])
      else
        # args[:app] is not a directory so must be a bundle id.
        if simulator_target?(args)
          args[:app] = app_path
        end
      end
    end

    # At this point :app is either nil because we are targeting a simulator
    # or it is a CFBundleIdentifier.
    if args[:app]
      # nothing to do because :bundle_id and :app are the same.
    else
      # User gave us no information about where the simulator app is located
      # so we have to auto detect it.  This RunLoop method raises an error
      # with a meaningful message based on the environment.  The message
      # includes suggestions about what to do next.
      run_loop_app = RunLoop::DetectAUT::Detect.new.app_for_simulator

      # This is not great - RunLoop is going to take this path and create a new
      # RunLoop::App.  This is the best we can do for now.
      args[:app] = run_loop_app.path
      args[:bundle_id] = run_loop_app.bundle_identifier
    end

    use_dylib = args[:inject_dylib]
    if use_dylib
      # User passed a Boolean, not a file.
      if use_dylib.is_a?(TrueClass)
        if simulator_target?(args)
          args[:inject_dylib] = Calabash::Cucumber::Dylibs.path_to_sim_dylib
        else
          raise RuntimeError, "Injecting a dylib is not supported when targeting a device"
        end
      else
        unless File.exist? use_dylib
          raise "Dylib does not exist at path: '#{use_dylib}'"
        end
      end
    end

    # Patch for bug in Xcode 6 GM + iOS 8 device testing.
    # http://openradar.appspot.com/radar?id=5891145586442240
    uia_strategy = default_uia_strategy(args, args[:sim_control], args[:instruments])
    args[:uia_strategy] ||= uia_strategy
    calabash_info "Using uia strategy: '#{args[:uia_strategy]}'"

    self.run_loop = new_run_loop(args)
    self.actions= Calabash::Cucumber::InstrumentsActions.new

    self.launch_args = args

    unless args[:calabash_lite]
      ensure_connectivity
      # skip compatibility check if injecting dylib
      unless args.fetch(:inject_dylib, false)
        check_server_gem_compatibility
      end
    end

    usage_tracker.post_usage_async
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
  #
  # @param [Hash] launch_args The launch arguments.
  # @param [RunLoop::SimControl] sim_control Used to find simulators.
  # @param [RunLoop::Instruments] instruments Used to find physical devices.
  def default_uia_strategy(launch_args, sim_control, instruments)

    xcode = sim_control.xcode
    if xcode.version_gte_7?
      :host
    else
      udid_or_name = launch_args[:device_target]

      # Can't make a determination, so return :host because it works everywhere.
      return :host if udid_or_name == nil || udid_or_name == ''

      # The default.
      # No DEVICE_TARGET is set and no option was passed to relaunch.
      return :preferences if udid_or_name.downcase.include?('simulator')

      simulator = sim_control.simulators.find do |sim|
        sim.instruments_identifier(xcode) == udid_or_name ||
              sim.udid == udid_or_name
      end

      return :preferences if simulator

      physical_device = instruments.physical_devices.find do |device|
        device.name == udid_or_name ||
              device.udid == udid_or_name
      end

      if physical_device
        if physical_device.version < RunLoop::Version.new('8.0')
          :preferences
        else
          :host
        end
      else
        # Return host because it works everywhere.
        :host
      end
    end
  end

  # @!visibility private
  def new_run_loop(args)

    last_err = nil

    num_retries = args[:launch_retries] || 5

    num_retries.times do
      begin
        return RunLoop.run(args)
      rescue RunLoop::TimeoutError => e
        last_err = e
      end
    end

    if simulator_target?(args)
      puts "Unable to launch app on Simulator."
    else
      puts "Unable to launch app on physical device"
    end
    raise StartError.new(last_err)
  end

  # @!visibility private
  def ensure_connectivity(options={})

    default_options = {
      :http_connection_retry => Calabash::Cucumber::Environment.http_connection_retries,
      :http_connection_timeout => Calabash::Cucumber::Environment.http_connection_timeout
    }

    merged_options = default_options.merge(options)

    max_retry_count = merged_options[:http_connection_retry]
    timeout = merged_options[:http_connection_timeout]

    start_time = Time.now

    max_retry_count.times do |try|
      RunLoop.log_debug("Trying to connect to Calabash Server: #{try + 1} of #{max_retry_count}")

      # Subtract the aggregate time we've spent thus far to make sure we're
      # not exceeding the request timeout across retries.
      time_diff = start_time + timeout - Time.now

      if time_diff <= 0
        break
      end

      begin
        http_status = ping_app
        return true if http_status == "200"
      rescue => _

      ensure
        sleep(1)
      end
    end

    raise RuntimeError,
%Q[Could not connect to the Calabash Server @ #{device_endpoint}.

See these two guides for help.

* https://github.com/calabash/calabash-ios/wiki/Testing-on-Physical-Devices
* https://github.com/calabash/calabash-ios/wiki/Testing-on-iOS-Simulators

1. Make sure your application is linked with Calabash.
2. Make sure there is not a firewall blocking traffic on #{device_endpoint}.
3. Make sure #{device_endpoint} is correct.

If your app is crashing at launch, find a crash report to determine the cause.

]
  end

  # @!visibility private
  def ping_app
    url = URI.parse(device_endpoint)

    http = Net::HTTP.new(url.host, url.port)
    res = http.start do |sess|
      sess.request Net::HTTP::Get.new(ENV['CALABASH_VERSION_PATH'] || "version")
    end
    status = res.code

    http.finish if http and http.started?

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
  def calabash_no_stop?
    ENV['NO_STOP']=="1"
  end

  # @deprecated 0.19.0
  # @!visibility private
  def calabash_no_launch?
    RunLoop.log_warn(%Q[
Calabash::Cucumber::Launcher #calabash_no_launch? and support for the NO_LAUNCH
environment variable has been removed from Calabash.  This always returns
true.  Please remove this method call from your hooks.
])
    true
  end

  # @!visibility private
  def device_target?
    (ENV['DEVICE_TARGET'] != nil) && (not simulator_target?)
  end

  # @!visibility private
  def discover_device_target(launch_args)
    ENV['DEVICE_TARGET'] || launch_args[:device_target]
  end

  # @!visibility private
  def simulator_target?(launch_args={})
    udid_or_name = discover_device_target(launch_args)

    return false if udid_or_name.nil? || udid_or_name == ''

    return true if udid_or_name.downcase.include?('simulator')

    return false if udid_or_name[RunLoop::Regex::DEVICE_UDID_REGEX, 0] != nil

    if xcode.version_gte_6?
      sim_control = launch_args[:sim_control] || RunLoop::SimControl.new
      simulator = sim_control.simulators.find do |sim|
        sim.instruments_identifier(xcode) == udid_or_name ||
              sim.udid == udid_or_name
      end

      !simulator.nil?
    else
      false
    end
  end

  # @!visibility private
  def app_path
    RunLoop::Environment.path_to_app_bundle || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH)
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
      server_version_string = `xcrun strings "#{path}" | grep -E 'CALABASH VERSION'`.chomp!
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

  # @!visibility private
  # Checks the server and gem version compatibility and generates a warning if
  # the server and gem are not compatible.
  #
  # @note  This is a proof-of-concept implementation and requires _strict_
  #  equality.  in the future we should allow minimum framework compatibility.
  #
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

    server_version = RunLoop::Version.new(server_version)
    gem_version = RunLoop::Version.new(Calabash::Cucumber::VERSION)
    min_server_version = RunLoop::Version.new(Calabash::Cucumber::MIN_SERVER_VERSION)

    if server_version < min_server_version
      msgs = [
            'The server version is not compatible with gem version.',
            'Please update your server.',
            'https://github.com/calabash/calabash-ios/wiki/Updating-your-Calabash-iOS-version',
            "       gem version: '#{gem_version}'",
            "min server version: '#{min_server_version}'",
            "    server version: '#{server_version}'"]
      calabash_warn("#{msgs.join("\n")}")
    end
    nil
  end
end
