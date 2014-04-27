
module Calabash
  module Cucumber

    # internal logging methods for calabash-ios gem
    module Logging

      # controls the the kind of information calabash logs
      #
      # this is considered one level above debug logging - maybe we should call
      # the info log level.
      #
      # @return [Boolean] +true+ if the <tt>CALABASH_FULL_CONSOLE_OUTPUT</tt> is set to
      #   '1'
      def full_console_logging?
        ENV['CALABASH_FULL_CONSOLE_OUTPUT'] == '1'
      end

      # controls whether or not calabash logs debug information
      #
      # @return [Boolean] +true+ if the <tt>DEBUG</tt> is set to '1'
      def debug_logging?
        ENV['DEBUG'] == '1'
      end

      # prints a blue/cyan warning message
      # @param [String] msg the message to print
      def calabash_warn(msg)
        begin
          warn "\033[34m\nWARN: #{msg}\033[0m"
        rescue
          warn "\nWARN: #{msg}"
        end
      end

      # prints a green info message
      # @param [String] msg the message to print
      def calabash_info(msg)
        begin
          puts "\033[32m\nINFO: #{msg}\033[0m"
        rescue
          puts "\nINFO: #{msg}"
        end
      end

      # controls printing of deprecation warnings
      #
      # to inhibit deprecation message set this to '1'
      #
      # inhibiting deprecation messages is not recommend
      CALABASH_NO_DEPRECATION = ENV['CALABASH_NO_DEPRECATION'] || '0'

      # returns +true+ if the <tt>CALABASH_NO_DEPRECATION</tt> variable is set
      # to +1+
      def no_deprecation_warnings?
        ENV['CALABASH_NO_DEPRECATION'] == '1'
      end

      # prints a deprecated message that includes the line number
      #
      # if ENV['CALABASH_NO_DEPRECATION'] == '1' then this method is a nop
      #
      # @param [String] version indicates when the feature was deprecated
      # @param [String] msg deprecation message (possibly suggesting alternatives)
      # @param [Symbol] type { :warn | :pending } - :pending will raise a
      #   cucumber pending exception
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