require 'calabash-cucumber/launcher'

module Calabash::Launcher
  @@launcher = nil

  def self.launcher
    @@launcher ||= Calabash::Cucumber::Launcher.new
  end

  def self.launcher=(launcher)
    @@launcher = launcher
  end

  def self.options
    env = ENV["CBX_LAUNCHER"]
    if env
      cbx_launcher = env.to_sym
      {
        :gesture_performer => :device_agent,
        :cbx_launcher => cbx_launcher
      }
    else
      {
        :gesture_performer => :instruments
      }
    end
  end

  def self.xcode
    Calabash::Cucumber::Environment.xcode
  end

  def self.instruments
    Calabash::Cucumber::Environment.instruments
  end

  def self.simctl
    Calabash::Cucumber::Environment.simctl
  end

  def self.environment
    {
      :simctl => self.simctl,
      :instruments => self.instruments,
      :xcode => self.xcode
    }
  end

  def self.target
    ENV['DEVICE_TARGET'] || RunLoop::Core.default_simulator
  end

  def self.target_is_simulator?
    self.launcher.simulator_target?
  end

  def self.target_is_physical_device?
    self.launcher.device_target?
  end

  def self.prepare_physical_device
    return if self.target_is_simulator?

    # Not yet.
    #self.ensure_app_installed
    #self.uninstall_cbx_runner
  end

  # Not yet.
  #
  # Trying to debug restarting problems.
  # def self.uninstall_cbx_runner
  #   return if self.target_is_simulator?
  #
  #   device = RunLoop::Device.device_with_identifier(self.target, self.environment)
  #   device_life_cycle = RunLoop::PhysicalDevice::IOSDeviceManager.new(device)
  #
  #   device_life_cycle.uninstall_app("com.apple.test.CBX-Runner")
  # end

  def self.ensure_app_installed
    # RunLoop handles this automatically.
    return if self.target_is_simulator?

    # This is a bit messy as we drop support BUNDLE_ID and support for handling
    # arm apps in the APP env var.
    path = ENV["DEVICE_APP"]

    app = RunLoop::App.new(path)
    device = RunLoop::Device.device_with_identifier(self.target, self.environment)
    device_life_cycle = RunLoop::PhysicalDevice::IOSDeviceManager.new(device)

    if !device_life_cycle.app_installed?(app.bundle_identifier)
      if !device_life_cycle.install_app(app)
        RunLoop.log_error %Q[

Could not install app on device:

   app: #{app}
device: #{device}

It is likely that you will need to set the CODE_SIGN_IDENTITY env variable to
allow code signing to succeed.  Check the output above for "ambiguous match"
errors during code signing.

Exiting 1.
]
        exit 1
      end
    end
  end
end

Before do |scenario|
  Calabash::Launcher.prepare_physical_device

  launcher = Calabash::Launcher.launcher
  options = {
    # Add launch options here.
  }

  merged_options = options.merge(Calabash::Launcher.options)
  launcher.relaunch(merged_options)
end

After do |scenario|
  calabash_exit
end
