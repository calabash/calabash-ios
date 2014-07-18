require 'sim_launcher'

module Calabash
  module Cucumber

    # This module has been replaced by Simulator Launcher
    #
    # @deprecated 0.9.169 Use the SimulatorLauncher class instead.
    module SimulatorHelper

      # Quits the simulator.
      #
      # This has been deprecated, but it appears in legacy launch hooks.
      #
      # Use this pattern instead:
      #
      # ```
      # at_exit do
      #   launcher = Calabash::Cucumber::Launcher.new
      #   if launcher.simulator_target?
      #     launcher.simulator_launcher.stop unless launcher.calabash_no_stop?
      #   end
      # end
      # ```
      #
      # @deprecated 0.9.169 replaced with SimulatorLauncher.new().stop
      def self.stop
        unless ENV['CALABASH_NO_DEPRECATION'] == '1'
          if RUBY_VERSION < '2.0'
            stack = Kernel.caller()[1..6].join("\n")
          else
            stack = Kernel.caller(0, 6)[1..-1].join("\n")
          end

          msgs = ['The Calabash::Cucumber::SimulatorHelper module has been replaced.',
                  'Please replace:',
                  '',
                  '    Calabash::Cucumber::SimulatorHelper.stop',
                  '',
                  'with this:',
                  '',
                  '    launcher = Calabash::Cucumber::Launcher.new',
                  '    launcher.simulator_launcher.stop',
                  '',
                  'The stack trace below will show you the line number you need to change.']

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
