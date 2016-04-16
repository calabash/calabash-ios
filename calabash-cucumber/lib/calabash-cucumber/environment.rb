module Calabash
  module Cucumber
    module Environment

      require "run_loop"

      # @!visibility private
      DEFAULTS = {
        # The endpoint of the app under test
        :aut_endpoint => "http://127.0.0.1:37265/",
        :http_connection_retries => 10,
        :http_connection_timeout => 60
      }

      # @!visibility private
      def self.xtc?
        RunLoop::Environment.xtc?
      end

      # @!visibility private
      def self.xcode
        return nil if self.xtc?
        @@xcode ||= RunLoop::Xcode.new
      end

      # @!visibility private
      def self.simctl
        return nil if self.xtc?
        @@simctl ||= RunLoop::Simctl.new
      end

      # @!visibility private
      def self.instruments
        return nil if self.xtc?
        @@instruments ||= RunLoop::Instruments.new
      end

      # @!visibility private
      def self.device_endpoint
        value = RunLoop::Environment.device_endpoint
        if value
          value
        else
          DEFAULTS[:aut_endpoint]
        end
      end

      # @!visibility private
      def self.http_connection_retries
        value = ENV["MAX_CONNECT_RETRIES"]
        if value && value != ""
          value.to_i
        else
          DEFAULTS[:http_connection_retries]
        end
      end

      # @!visibility private
      def self.http_connection_timeout
        value = ENV["CONNECTION_TIMEOUT"]
        if value && value != ""
          value.to_i
        else
          DEFAULTS[:http_connection_timeout]
        end
      end

      # @!visibility private
      def self.reset_between_scenarios?
        ENV["RESET_BETWEEN_SCENARIOS"] == "1"
      end

      # @!visibility private
      def self.quit_app_after_scenario?
        value = ENV["QUIT_APP_AFTER_SCENARIO"]

        if value == "0"
          false
        elsif value == "1"
          true
        else
          !self.no_stop?
        end
      end

      private

      # @visibility private
      # @deprecated 0.19.0 - replaced with QUIT_APP_AFTER_SCENARIO
      #
      # Silently deprecated.  Deprecate in 0.20.0.
      def self.no_stop?
        value = ENV["NO_STOP"]
        if value
          return_value = value == "1"

=begin
          if return_value
            replacement = "$ QUIT_APP_AFTER_SCENARIO=0"
          else
            replacement = "$ QUIT_APP_AFTER_SCENARIO=1"
          end
          RunLoop.deprecated("0.19.0",
%Q{The 'NO_STOP' env variable has been been replaced with: QUIT_APP_AFTER_SCENARIO

Please replace NO_STOP with QUIT_APP_AFTER_SCENARIO.

#{replacement}

The default behavior is to quit the app after each scenario.
})
=end
          return_value
        else
          false
        end
      end
    end
  end
end
