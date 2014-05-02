require 'sim_launcher'

module Calabash
  module Cucumber

    # this module has been replaced by Simulator Launcher
    #
    # @deprecated Use the SimulatorLauncher class instead
    # @since 0.9.169
    module SimulatorHelper

      # quits the simulator
      #
      # this has been deprecated, but it appears in legacy launch hooks
      #
      # use this pattern instead:
      #
      #   at_exit do
      #     launcher = Calabash::Cucumber::Launcher.new
      #     if launcher.simulator_target?
      #       launcher.simulator_launcher.stop unless launcher.calabash_no_stop?
      #     end
      #   end
      #
      # @deprecated use the SimulatorLauncher.new().stop instead
      def self.stop
        unless ENV['CALABASH_NO_DEPRECATION'] == '1'
          if RUBY_VERSION < '2.0'
            stack = Kernel.caller()[1..6].join("\n")
          else
            stack = Kernel.caller(0, 6)[1..-1].join("\n")
          end

          msgs = ['Calabash::Cucumber::SimulatorHelper module has been replaced',
                  'please update your code to use this pattern:',
                  '  launcher = Calabash::Cucumber::Launcher.new',
                  '  launcher.simulator_launcher.stop']

          msg = "deprecated '0.9.169' - #{msgs.join("\n")}\n#{stack}"

          begin
            STDERR.puts "\033[34m\nWARN: #{msg}\033[0m"
          rescue
            STDERR.puts "\nWARN: #{msg}"
          end
        end
        simulator = SimLauncher::Simulator.new()
        simulator.quit_simulator
        simulator
      end

    end
  end
end
