
module Calabash
  class Launchctl
    require "singleton"
    include Singleton

    require "calabash-cucumber/launcher"
    require "calabash-cucumber/environment"

    attr_reader :first_launch
    attr_reader :launcher

    def initialize
      @first_launch = true
      @launcher = Calabash::Cucumber::Launcher.new
    end

    def launch(options)
      launcher.relaunch(options)
      @first_launch = false
    end

    def launcher
      @launcher
    end

    def first_launch
      @first_launch
    end

    def shutdown
      # Might not be necessary?
      launcher.instance_variable_set(:@run_loop, nil)
      launcher.instance_variable_set(:@gesture_performer, nil)
      @first_launch = true
    end

    def lp_server_running?
      begin
        running = launcher.ping_app
      rescue Errno::ECONNREFUSED => _
        running = false
      end

      running
    end

    def device_agent_running?
      if !options[:cbx_launcher]
        raise RuntimeError, "Don't call this method if you are running with Instruments"
      end

      if launcher.gesture_performer.nil?
        return false
      end

      launcher.gesture_performer.device_agent.running?
    end

    def running?
      return false if first_launch
      return false if !launcher.run_loop
      return false if !launcher.gesture_performer

      return false if !lp_server_running?

      running = true

      if options[:cbx_launcher]
        device_agent_running?
      end

      running
    end

    def xcode
      Calabash::Cucumber::Environment.xcode
    end

    def instruments
      Calabash::Cucumber::Environment.instruments
    end

    def simctl
      Calabash::Cucumber::Environment.simctl
    end

    def environment
      {
        :simctl => self.simctl,
        :instruments => self.instruments,
        :xcode => self.xcode
      }
    end

    def options
      @options ||= begin
        env = ENV["CBX_LAUNCHER"]
        if env
          cbx_launcher = env.to_sym
          cbx = {
            :gesture_performer => :device_agent,
            :cbx_launcher => cbx_launcher
          }
        else
          cbx = {
            :gesture_performer => :instruments
          }
        end

        if cbx[:cbx_launcher] == :xcodebuild
          cbx[:shutdown_device_agent_before_launch] = true
        end

        cbx.merge(environment)
      end
    end

    def device
      @device ||= RunLoop::Device.detect_device({}, xcode, simctl, instruments)
    end
  end
end

Before("@restart_before") do |_|
  calabash_exit
  Calabash::Launchctl.instance.shutdown
end

Before do |scenario|

  options = {
    # Add launch options here.
  }

  merged_options = options.merge(Calabash::Launchctl.instance.options)

  if !Calabash::Launchctl.instance.running?
    Calabash::Launchctl.instance.launch(merged_options)
  end
end

After("@restart_after") do |_|
  calabash_exit
  Calabash::Launchctl.instance.shutdown
end

After do |scenario|

end
