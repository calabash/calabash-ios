module Calabash
  module Cucumber
    module Environment

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
        @@simctl ||= RunLoop::SimControl.new
      end

      # @!visibility private
      def self.instruments
        return nil if self.xtc?
        @@instruments ||= RunLoop::Instruments.new
      end

      # @!visibility private
      def self.device_target
        value = RunLoop::Environment.device_target
        if value
          if value == "simulator"
            identifier = RunLoop::Core.default_simulator
          elsif value == "device"
            identifier = RunLoop::Core.detect_connected_device
          else
            identifier = value
          end
        else
          identifier = RunLoop::Core.default_simulator
        end

        identifier
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
    end
  end
end
