module Calabash
  module Cucumber
    module Environment

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
    end
  end
end
