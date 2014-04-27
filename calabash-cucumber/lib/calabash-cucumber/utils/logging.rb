
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

    end
  end
end