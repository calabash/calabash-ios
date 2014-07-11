
module Calabash
  module Cucumber

    # Internal logging methods for the calabash-ios gem.
    module Logging

      # @!visibility private
      # Has full console logging been enabled?
      #
      # The return value is controlled by the `CALABASH_FULL_CONSOLE_OUTPUT`
      # environment variable.
      #
      # This is considered one level above debug logging - maybe we should call
      # the info log level.
      #
      # @return [Boolean] Returns `true` if full logging has been enabled.
      def full_console_logging?
        ENV['CALABASH_FULL_CONSOLE_OUTPUT'] == '1'
      end

      # @!visibility private
      # Has debug logging been enabled?
      #
      # The return value is controlled by the `DEBUG` environment variable.
      #
      # @return [Boolean] Returns `true` if debug logging has been enabled.
      def debug_logging?
        ENV['DEBUG'] == '1'
      end

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
      # Controls printing of deprecation warnings.
      #
      # To inhibit deprecation message set this to '1'
      #
      # Inhibiting deprecation messages is not recommend.
      CALABASH_NO_DEPRECATION = ENV['CALABASH_NO_DEPRECATION'] || '0'

      # @!visibility private
      # Have deprecation warnings been turned off?
      #
      # The return value is controlled but the `CALABASH_NO_DEPRECATION`
      # environment variable.
      def no_deprecation_warnings?
        ENV['CALABASH_NO_DEPRECATION'] == '1'
      end

      # @!visibility private
      # Prints a deprecated message that includes the line number.
      #
      # If deprecation warns have been turned off this method does nothing.
      #
      # @param [String] version indicates when the feature was deprecated
      # @param [String] msg deprecation message (possibly suggesting alternatives)
      # @param [Symbol] type { :warn | :pending } - :pending will raise a
      #   cucumber pending exception
      # @return [void]
      def _deprecated(version, msg, type)
        allowed = [:pending, :warn]
        unless allowed.include?(type)
          raise "type '#{type}' must be on of '#{allowed}'"
        end

        unless no_deprecation_warnings?

          if RUBY_VERSION < '2.0'
            stack = Kernel.caller()[1..6].join("\n")
          else
            stack = Kernel.caller(0, 6)[1..-1].join("\n")
          end

          msg = "deprecated '#{version}' - '#{msg}'\n#{stack}"

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
end