
module Calabash
  module Cucumber
    module Abstract

      # @!visibility private
      class AbstractMethodError < StandardError; end

      # @!visibility private
      def abstract_method!
        if Kernel.method_defined?(:caller_locations)
          method_name = caller_locations.first.label
        else
          method_name = caller.first[/\`(.*)\'/, 1]
        end

        raise AbstractMethodError.new("Abstract method '#{method_name}'")
      end
    end
  end
end

