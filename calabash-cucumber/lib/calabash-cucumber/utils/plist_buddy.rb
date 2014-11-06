require 'run_loop'

module Calabash
  module Cucumber
    # @!visibility private
    # A module for reading and writing property list values.
    module PlistBuddy

      # Reads key from file and returns the result.
      # @param [String] key the key to inspect (may not be nil or empty)
      # @param [String] file the plist to read
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [String] the value of the key
      # @raise [ArgumentError] if nil or empty key
      def plist_read(key, file, opts={})
        RunLoop::PlistBuddy.new.plist_read(key, file, opts)
      end

      # Checks if the key exists in plist.
      # @param [String] key the key to inspect (may not be nil or empty)
      # @param [String] file the plist to read
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [Boolean] true if the key exists in plist file
      def plist_key_exists?(key, file, opts={})
        plist_read(key, file, opts) != nil
      end

      # Replaces or creates the value of key in the file.
      #
      # @param [String] key the key to set (may not be nil or empty)
      # @param [String] type the plist type (used only when adding a value)
      # @param [String] value the new value
      # @param [String] file the plist to read
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [Boolean] true if the operation was successful
      # @raise [ArgumentError] if nil or empty key
      def plist_set(key, type, value, file, opts={})
        RunLoop::PlistBuddy.new.plist_set(key, type, value, file, opts)
      end
    end
  end
end
