module Calabash
  module Cucumber
    module Environment

      def self.device_target
        value = ENV["DEVICE_TARGET"]

        if value.nil? || value == ""
          nil
        else
          value
        end
      end
    end
  end
end
