
module Calabash
  module Cucumber

    # Internal logging methods for the calabash-ios gem.
    module Logging

      # Prints a blue warning message.
      # @param [String] msg the message to print
      # @return [void]
      def calabash_warn(msg)
        begin
          warn "\033[34m\nWARN: #{msg}\033[0m"
        rescue
          warn "\nWARN: #{msg}"
        end
      end

      # Prints a green info message.
      # @param [String] msg the message to print
      # @return [void]
      def calabash_info(msg)
        begin
          puts "\033[32m\nINFO: #{msg}\033[0m"
        rescue
          puts "\nINFO: #{msg}"
        end
      end

      # @!visibility private
      # Prints a deprecated message that includes the line number.
      #
      # If deprecation warns have been turned off this method does nothing.
      #
      # @param [String] version indicates when the feature was deprecated
      # @param [String] msg deprecation message (possibly suggesting alternatives)
      # @param [Symbol] type { :warn | :pending } - :pending will raise a
      #   cucumber pending error
      # @return [void]
      def _deprecated(version, msg, type)
        allowed = [:pending, :warn]
        unless allowed.include?(type)
          raise "type '#{type}' must be on of '#{allowed}'"
        end

        stack = Kernel.caller(0, 6)[1..-1].join("\n")

        msg = "deprecated '#{version}' - #{msg}\n#{stack}"

        if type.eql?(:pending)
          pending(msg)
        else
          begin
            warn "\033[34m\nWARN: #{msg}\033[0m"
          rescue
            warn "\nWARN: #{msg}"
          end
        end
      end

    end
  end
end
