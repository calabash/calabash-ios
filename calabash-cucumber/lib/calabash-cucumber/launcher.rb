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
      require "calabash-cucumber/gestures/performer"
      require "calabash-cucumber/gestures/instruments"
      require "calabash-cucumber/usage_tracker"
      require "calabash-cucumber/dylibs"
      require "calabash-cucumber/environment"
      require "calabash-cucumber/http/http"
      require "run_loop"

      # @!visibility private
      DEFAULTS = {
        :launch_retries => 5
      }

      # @!visibility private
      @@launcher = nil

      # @!visibility private
      @@launcher = nil

      # @!visibility private
      attr_accessor :run_loop

      # @!visibility private
      attr_accessor :actions

      # @!visibility private
      attr_accessor :launch_args

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
          msg << "If your app is already running, try `console_attach`"
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
        return l if l && l.attached_to_gesture_performer?
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
          self.actions = Calabash::Cucumber::Gestures::Instruments.new(self.run_loop)
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
        launcher = Launcher::launcher_if_used
        if !launcher
          false
        else
          launcher.instruments?
        end
      end

      # @!visibility private
      def instruments?
        attached_to_gesture_performer? &&
          @actions.class.send(:name) == :instruments
      end

      # @!visibility private
      def attached_to_gesture_performer?
        @actions != nil
      end

      # @deprecated 0.19.3 - replaced with attached_to_gesture_performer?
      # TODO remove in 0.20.0
      # @!visibility private
      def active?
        RunLoop.deprecated("0.19.3", "replaced with attached_to_gesture_performer?")
        attached_to_gesture_performer?
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

      # Is the current device under test a physical device?
      #
      # Can be used before or after the application has been launched.
      #
      # Maintainers, please do not call this method.
      #
      # @param [Hash] options This argument is deprecated since 0.19.0.
      #
      # @return [Boolean] True if the device under test a physical device.
      def device_target?(options={})
        if Calabash::Cucumber::Environment.xtc?
          true
        elsif @device
          @device.device?
        else
          detect_device(options).physical_device?
        end
      end

      # Is the current device under test a simulator?
      #
      # Can be used before or after the application has been launched.
      #
      # Maintainers, please do not call this method.
      #
      # @param [Hash] options This argument is deprecated since 0.19.0.
      #
      # @return [Boolean] True if the device under test a simulator.
      def simulator_target?(options={})
        if Calabash::Cucumber::Environment.xtc?
          false
        elsif @device
          @device.simulator?
        else
          detect_device(options).simulator?
        end
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
        if device.is_a?(RunLoop::Device)
          device_target = device
        else
          device_target = detect_device(:device => device)
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
      # * `:device` - simulator or device to target.
      # * `:reset_app_sandbox - reset the app's data (sandbox) before testing
      #
      # and many other behaviors.
      #
      # Many of these behaviors can be be controlled by environment variables. The
      # most important environment variables are `APP`, `DEVICE_TARGET`, and
      # `DEVICE_ENDPOINT`.
      #
      # @param {Hash} launch_options optional arguments to control the how the app is launched
      def relaunch(launch_options={})
        simctl = launch_options[:simctl] || launch_options[:sim_control]
        instruments = launch_options[:instruments]
        xcode = launch_options[:xcode]

        options = launch_options.clone

        # Reusing Simctl, Instruments, and Xcode can speed up launches.
        options[:simctl] = simctl || Calabash::Cucumber::Environment.simctl
        options[:instruments] = instruments || Calabash::Cucumber::Environment.instruments
        options[:xcode] = xcode || Calabash::Cucumber::Environment.xcode
        options[:inject_dylib] = detect_inject_dylib_option(launch_options)

        self.launch_args = options

        self.run_loop = new_run_loop(options)
        self.actions = Calabash::Cucumber::Gestures::Instruments.new(self.run_loop)

        if !options[:calabash_lite]
          Calabash::Cucumber::HTTP.ensure_connectivity
          check_server_gem_compatibility
        end

        usage_tracker.post_usage_async

        # :on_launch to the Cucumber World if:
        # * the Launcher is part of the World (it is not by default).
        # * Cucumber responds to :on_launch.
        self.send(:on_launch) if self.respond_to?(:on_launch)

        self
      end

      # @!visibility private
      def new_run_loop(args)
        last_err = nil
        num_retries = args[:launch_retries] || DEFAULTS[:launch_retries]
        num_retries.times do
          begin
            return RunLoop.run(args)
          rescue RunLoop::TimeoutError => e
            last_err = e
          end
        end

        raise Calabash::Cucumber::LaunchError.new(last_err)
      end

      # @!visibility private
      # TODO Should call calabash exit route to shutdown the server.
      def stop
        RunLoop.stop(run_loop) if run_loop && run_loop[:pid]
      end

      # Should Calabash quit the app under test after a Scenario?
      #
      # Control this behavior using the QUIT_APP_AFTER_SCENARIO variable.
      #
      # The default behavior is to quit after every Scenario.
      def quit_app_after_scenario?
        Calabash::Cucumber::Environment.quit_app_after_scenario?
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
        # Only check once.
        return server_version if server_version

        version_string = self.device.server_version

        @server_version = RunLoop::Version.new(version_string)
        gem_version = RunLoop::Version.new(Calabash::Cucumber::VERSION)
        min_server_version = RunLoop::Version.new(Calabash::Cucumber::MIN_SERVER_VERSION)

        if @server_version < min_server_version
          msgs = [
            "The server version is not compatible with gem version.",
            "Please update your server.",
            "https://github.com/calabash/calabash-ios/wiki/Updating-your-Calabash-iOS-version",
            "       gem version: '#{gem_version}'",
            "min server version: '#{min_server_version}'",
            "    server version: '#{@server_version}'"]
          RunLoop.log_warn("#{msgs.join("\n")}")
        end
        @server_version
      end

      # @deprecated 0.19.0 - replaced with #quit_app_after_scenario?
      # TODO remove in 0.20.0
      # @!visibility private
      def calabash_no_stop?
        # Not yet.  Save for 0.20.0.
        # RunLoop.deprecated("0.19.0", "replaced with quit_app_after_scenario")
        !quit_app_after_scenario?
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def calabash_no_launch?
        RunLoop.log_warn(%Q[
Calabash::Cucumber::Launcher #calabash_no_launch? and support for the NO_LAUNCH
environment variable has been removed from Calabash.  This always returns
true.  Please remove this method call from your hooks.
])
        false
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement.
      # TODO remove in 0.20.0
      def default_uia_strategy(launch_args, sim_control, instruments)
        RunLoop::deprecated("0.19.0", "This method has been removed.")
        :host
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def detect_connected_device?
        RunLoop.deprecated("0.19.0", "No replacement")
        false
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def default_launch_args
        RunLoop.deprecated("0.19.0", "No replacement")
        {}
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def discover_device_target(launch_args)
        RunLoop.deprecated("0.19.0", "No replacement")
        nil
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def app_path
        RunLoop.deprecated("0.19.0", "No replacement")
        nil
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def xcode
        RunLoop.deprecated("0.19.0", "Use Calabash::Cucumber::Environment.xcode")
        Calabash::Cucumber::Environment.xcode
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def ensure_connectivity
        RunLoop.deprecated("0.19.0", "No replacement")
        Calabash::Cucumber::HTTP.ensure_connectivity
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement - this method is a no op
      #
      # #relaunch will now send ":on_launch" to the Cucumber World if:
      # * the Launcher is part of the World (it is not by default).
      # * Cucumber responds to :on_launch.
      # TODO remove in 0.20.0
      def calabash_notify(_)
        false
      end

      # @!visibility private
      # @deprecated 0.19.0  - no replacement.
      # TODO remove in 0.20.0
      def server_version_from_server
        RunLoop.deprecated("0.19.0", "No replacement")
        server_version
      end

      # @!visibility private
      # @deprecated 0.19.0 - no replacement
      # TODO remove in 0.20.0
      def server_version_from_bundle(app_bundle_path)
        RunLoop.deprecated("0.19.0", "No replacement")
        options = {:app => app_bundle_path }
        app_details = RunLoop::DetectAUT.detect_app_under_test(options)
        app = app_details[:app]

        if app.respond_to?(:calabash_server_version)
          app.calabash_server_version
        else
          nil
        end
      end

      private

      # @!visibility private
      #
      # A convenience wrapper around RunLoop::Device.detect_device
      def detect_device(options)
        xcode = Calabash::Cucumber::Environment.xcode
        simctl = Calabash::Cucumber::Environment.simctl
        instruments = Calabash::Cucumber::Environment.instruments
        RunLoop::Device.detect_device(options, xcode, simctl, instruments)
      end

      # The version of the embedded LPServer
      # @return RunLoop::Version
      attr_reader :server_version

      # @!visibility private
      #
      # @param [Hash] options the launch options passed by the user
      def detect_inject_dylib_option(options)
        return nil if !options[:inject_dylib]

        value = options[:inject_dylib]

        # Test for boolean true.
        if [true].include?(value)
          # Injection is only supported on simulators, so this cool for now.
          # Depend on run-loop to raise an error.
          Calabash::Cucumber::Dylibs.path_to_sim_dylib
        else
          # User supplied a path
          value
        end
      end
    end
  end
end

