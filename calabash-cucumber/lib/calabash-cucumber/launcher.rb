module Calabash
  module Cucumber

    # Raised when calabash cannot launch the app.
    class LaunchError < RuntimeError
      attr_accessor :error

      def initialize(err)
        self.error= err
      end

      # @!visibility private
      def to_s
        "#{super.to_s}: #{error}"
      end
    end

    # Raised when Calabash cannot find a device based on DEVICE_TARGET
    class DeviceNotFoundError < RuntimeError ; end

    # Launch apps on iOS Simulators and physical devices.
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
    # * **Pro Tip:** Set the `QUIT_APP_AFTER_SCENARIO=0` env variable so calabash
    # does not quit your application after a failed Scenario.
    class Launcher

      require "calabash-cucumber/device"
      require "calabash-cucumber/actions/instruments_actions"
      require "calabash-cucumber/usage_tracker"
      require "calabash-cucumber/dylibs"
      require "calabash-cucumber/environment"
      require "calabash-cucumber/http/http"
      require "run_loop"

      # @!visibility private
      @@launcher = nil

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
      attr_accessor :actions

      # @!visibility private
      attr_accessor :launch_args

      # @!visibility private
      attr_reader :xcode

      # @!visibility private
      attr_reader :usage_tracker

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
      #
      # Use this method to see if your app is already running.  This is helpful
      # if you have Scenarios that don't require an app relaunch.
      #
      # @raise Raises an error if the server does not respond.
      def ping_app
        Calabash::Cucumber::HTTP.ping_app
      end

      # @!visibility private
      #
      # This Calabash::Cucumber::Device instance is required because we cannot
      # determine the iOS version of physical devices.
      #
      # This device instance can only be created _if the server is running_.
      #
      # We need this instance because we need to know at runtime whether or
      # not to translate touch coordinates in the client or on the server. For
      # iOS >= 8.0 translation is done on the server.  Further, we need a
      # Device instance for iOS < 8 so we can perform the necessary
      # coordinate normalization - based on the device attributes.
      #
      # We also need this instance to determine the default uia strategy.
      #
      # +1 for tools to ask physical devices about attributes.
      def device
        @device ||= lambda do
          _, body = Calabash::Cucumber::HTTP.ensure_connectivity
          endpoint = Calabash::Cucumber::Environment.device_endpoint
          Calabash::Cucumber::Device.new(endpoint, body)
        end.call
      end

      # @!visibility private
      #
      # Legacy API. This is a required method.  Do not remove
      def device=(new_device)
        @device = new_device
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
      def actions
        attach if @actions.nil?
        @actions
      end

      # @!visibility private
      # @see Calabash::Cucumber::Core#console_attach
      def self.attach
        l = launcher
        return l if l && l.active?
        l.attach
      end

      # @!visibility private
      # @see Calabash::Cucumber::Core#console_attach
      def attach(options={})
        if Calabash::Cucumber::Environment.xtc?
          raise "This method is not available on the Xamarin Test Cloud"
        end

        default_options = {:http_connection_retry => 1,
                           :http_connection_timeout => 10}
        merged_options = default_options.merge(options)

        self.run_loop = RunLoop::HostCache.default.read

        set_device_target_after_attach(self.run_loop)

        begin
          Calabash::Cucumber::HTTP.ensure_connectivity(merged_options)
        rescue Calabash::Cucumber::ServerNotRespondingError => _
          device_endpoint = Calabash::Cucumber::Environment.device_endpoint
          RunLoop.log_warn(
%Q[

Could not connect to Calabash Server @ #{device_endpoint}.

If your app is running, check that you have set the DEVICE_ENDPOINT correctly.

If your app is not running, it was a mistake to call this method.

http://calabashapi.xamarin.com/ios/Calabash/Cucumber/Core.html#console_attach-instance_method

Try `start_test_server_in_background`

])

          # Nothing to do except log the problem and exit early.
          return false
        end

        if self.run_loop[:pid]
          self.actions = Calabash::Cucumber::InstrumentsActions.new
        else
          RunLoop.log_warn(
%Q[

Connected to an app that was not launched by Calabash using instruments.

Queries will work, but gestures will not.

])
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

      # A reference to the current launcher (instantiates a new one if needed).
      # @return {Calabash::Cucumber::Launcher} the current launcher
      def self.launcher
        @@launcher ||= Calabash::Cucumber::Launcher.new
      end

      # Get a reference to the current launcher (does not instantiate a new one if unset).
      # @return {Calabash::Cucumber::Launcher} the current launcher or nil
      def self.launcher_if_used
        @@launcher
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
        if device.nil? || device == ""
          device_target = ensure_device_target
        elsif device.is_a?(RunLoop::Device)
          device_target = device
        else
          options = {
            :sim_control => Calabash::Cucumber::Environment.simctl,
            :instruments => Calabash::Cucumber::Environment.instruments
          }
          device_target = RunLoop::Device.device_with_identifier(device, options)
        end

        if device_target.physical_device?
          raise ArgumentError,
%Q{
Cannot reset: #{device_target}.

Resetting physical devices is not supported.
}
        end

        RunLoop::CoreSimulator.erase(device_target)
        device_target
      end

      # @!visibility private
      def default_launch_args
        # APP_BUNDLE_PATH
        # BUNDLE_ID
        # APP (unifies APP_BUNDLE_PATH, BUNDLE_ID)
        # DEVICE_TARGET
        # RESET_BETWEEN_SCENARIOS
        # DEVICE
        # QUIT_APP_AFTER_SCENARIO

        args = {
          :reset => Calabash::Cucumber::Environment.reset_between_scenarios?,
          :bundle_id => ENV['BUNDLE_ID'],
          # TODO: Deprecate this key.  Use :quit_app_after_scenario.
          :no_stop => quit_app_after_scenario?,
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

        # Patch until RunLoop >= 2.0.10 is released
        if !args[:uia_strategy]
          args[:uia_strategy] = :host
        end

        self.run_loop = new_run_loop(args)
        self.actions= Calabash::Cucumber::InstrumentsActions.new

        self.launch_args = args

        unless args[:calabash_lite]
          Calabash::Cucumber::HTTP.ensure_connectivity
          # skip compatibility check if injecting dylib
          unless args.fetch(:inject_dylib, false)
            check_server_gem_compatibility
          end
        end

        usage_tracker.post_usage_async
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
        raise Calabash::Cucumber::LaunchError.new(last_err)
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

      # @deprecated 0.19.0 - replaced with #quit_app_after_scenario?
      # @!visibility private
      def calabash_no_stop?
        # Not yet.  Save for 0.20.0.
        # RunLoop.deprecated("0.19.0", "replaced with quit_app_after_scenario")
        !quit_app_after_scenario?
      end

      # Should Calabash quit the app under test after a Scenario?
      #
      # Control this behavior using the QUIT_APP_AFTER_SCENARIO variable.
      #
      # The default behavior is to quit after every Scenario.
      def quit_app_after_scenario?
        Calabash::Cucumber::Environment.quit_app_after_scenario?
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
          RunLoop.log_warn("Could not find executable in '#{app_bundle_path}'")

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
          RunLoop.log_warn("Could not find server version by inspecting the binary strings table")

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
          RunLoop.log_warn("Server version could not be found - skipping compatibility check")
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
          RunLoop.log_warn("#{msgs.join("\n")}")
        end
        nil
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement.
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
        RunLoop::deprecated("0.19.0", "This method has been removed.")
        :host
      end

      private

      # @!visibility private
      # @return [RunLoop::Device] A RunLoop::Device instance.
      def ensure_device_target
        begin
          @run_loop_device ||= Calabash::Cucumber::Environment.run_loop_device
        rescue ArgumentError => e
          raise Calabash::Cucumber::DeviceNotFoundError,
                %Q[Could not find a matching device in your environment.

#{e.message}

To see what devices are available on your machine, use instruments:

$ xcrun instruments -s devices

]
        end
      end

      # @!visibility private
      #
      # Called from the World.console_attach => #attach method to populate
      # the instance variable because `relaunch` is not called.
      def set_device_target_after_attach(run_loop_hash)
        identifier = run_loop_hash[:udid]

        options = {
          :sim_control => Calabash::Cucumber::Environment.simctl,
          :instruments => Calabash::Cucumber::Environment.instruments
        }

        begin
           @run_loop_device = RunLoop::Device.device_with_identifier(identifier, options)
        rescue ArgumentError => _
          # For now we will swallow any error - it is not clear yet if it will be
          # important to make this connection.
          @run_loop_device = nil
        end
      end
    end
  end
end

