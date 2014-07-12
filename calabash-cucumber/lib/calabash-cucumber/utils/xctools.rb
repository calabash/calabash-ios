require 'open3'

module Calabash
  module Cucumber

    # methods for interacting with the xcode tools
    module XcodeTools

      # returns the path to the current developer directory
      #
      # From the man pages:
      #
      #  $ man xcode-select
      #  DEVELOPER_DIR
      #  Overrides the active developer directory. When DEVELOPER_DIR is set, its value
      #  will be used instead of the system-wide active developer directory.
      #
      # @return [String] path to current developer directory
      def xcode_developer_dir
        # respect DEVELOPER_DIR
        return ENV['DEVELOPER_DIR'] if ENV['DEVELOPER_DIR']
        # fall back to xcode-select
        `xcode-select --print-path`.chomp
      end

      # returns the path to the current developer usr/bin directory
      # @return [String] path to the current xcode binaries
      def xcode_bin_dir
        File.expand_path("#{xcode_developer_dir}/usr/bin")
      end

      # method for interacting with instruments
      #
      #              instruments #=> /Applications/Xcode.app/Contents/Developer/usr/bin/instruments
      #    instruments(:version) #=> 5.1.1
      #       instruments(:sims) #=> < list of known simulators >
      #
      # @param [String] cmd controls the return value.  currently accepts nil,
      #   :sims, and :version as valid parameters
      # @return [String] based on the value of +cmd+ version, a list known
      #   simulators, or the path to the instruments binary
      # @raise [ArgumentError] if invalid +cmd+ is passed
      def instruments(cmd=nil)
        instruments = "#{xcode_bin_dir}/instruments"
        return instruments if cmd == nil

        case cmd
          when :version
            # instruments, version 5.1.1 (55045)
            # noinspection RubyUnusedLocalVariable
            Open3.popen3("#{instruments}") do |stdin, stdout, stderr, wait_thr|
              stderr.read.chomp.split(' ')[2]
            end
          when :sims
            devices = `#{instruments} -s devices`.chomp.split("\n")
            devices.select { |device| device.downcase.include?('simulator') }
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
      # @return [Boolean] true iff the version is >= 5.*
      def instruments_supports_hyphen_s?(version=instruments(:version))
        tokens = version.split('.')
        return false if tokens[0].to_i < 5
        return false if tokens[1].to_i < 1
        true
      end

      # returns a list of installed simulators by calling:
      #
      #    $ instruments -s devices
      #
      # and parsing the output
      # @return [Array<String>] an array of simulator names suitable for passing
      #   to instruments or xcodebuild
      # @raise [RuntimeError] if the currently active instruments version does
      #   not support the -s flag
      def installed_simulators
        unless instruments_supports_hyphen_s?
          raise(RuntimeError, "instruments '#{instruments(:version)}' does not support '-s devices' arguments")
        end
        instruments(:sims)
      end

    end
  end
end