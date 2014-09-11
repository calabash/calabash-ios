require 'open3'
require 'run_loop'

module Calabash
  module Cucumber

    # @!visibility private
    # Methods for interacting with the xcode tools.
    module XcodeTools

      # Returns the path to the current developer directory.
      #
      # From the man pages:
      #
      # ```
      # $ man xcode-select
      # DEVELOPER_DIR
      # Overrides the active developer directory. When DEVELOPER_DIR is set,
      # its value will be used instead of the system-wide active developer
      # directory.
      #```
      #
      # @return [String] path to current developer directory
      def xcode_developer_dir
        RunLoop::XCTools.new.xcode_developer_dir
      end

      # @deprecated 0.10.0 not replaced
      # Returns the path to the current developer `usr/bin` directory.
      # @return [String] path to the current xcode binaries
      def xcode_bin_dir
        _deprecated('0.10.0', 'no replacement', :warn)
        File.expand_path("#{xcode_developer_dir}/usr/bin")
      end

      # Method for interacting with instruments.
      #
      # @example Getting the path to instruments.
      #  instruments #=> /Applications/Xcode.app/Contents/Developer/usr/bin/instruments
      #
      # @example Getting a the version of instruments.
      #  instruments(:version) #=> 5.1.1
      #
      # @example Getting list of known simulators.
      #  instruments(:sims) #=> < list of known simulators >
      #
      # @param [String] cmd controls the return value.  currently accepts nil,
      #   :sims, and :version as valid parameters
      # @return [String] based on the value of +cmd+ version, a list known
      #   simulators, or the path to the instruments binary
      # @raise [ArgumentError] if invalid +cmd+ is passed
      def instruments(cmd=nil)
        instruments = 'xcrun instruments'
        return instruments if cmd == nil
        case cmd
          when :version
            RunLoop::XCTools.new.instruments(cmd).to_s
          when :sims
            RunLoop::XCTools.new.instruments(cmd)
          else
            candidates = [:version, :sims]
            raise(ArgumentError, "expected '#{cmd}' to be one of '#{candidates}'")
        end
      end

      # Does the instruments `version` accept the -s flag?
      #
      # @example
      #  instruments_supports_hyphen_s?('4.6.3') => false
      #  instruments_supports_hyphen_s?('5.0.2') => true
      #  instruments_supports_hyphen_s?('5.1')   => true
      #
      # @param [String] version (instruments(:version))
      #   a major.minor[.patch] version string
      #
      # @return [Boolean] true if the version is >= 5.*
      def instruments_supports_hyphen_s?(version)
        RunLoop::XCTools.new.instruments_supports_hyphen_s?(version)
      end

      # Returns a list of installed simulators by calling `$ instruments -s devices`.
      # and parsing the output
      # @return [Array<String>] an array of simulator names suitable for passing
      #   to instruments or xcodebuild
      # @raise [RuntimeError] if the currently active instruments version does
      #   not support the -s flag
      def installed_simulators
        instruments(:sims)
      end
    end
  end
end
