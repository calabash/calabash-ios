require 'calabash-cucumber/utils/logging'

module Calabash
  module Cucumber

    include Calabash::Cucumber::Logging

    # module for reading and writing property list values
    module PlistBuddy

      # reads +key+ from +file+ and returns the result
      # @param [String] key the key to inspect (may not be nil or empty)
      # @param [String] file the plist to read
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [nil] if +key+ does not exist
      # @return [String] if the +key+ exists then the value of +key+ (error)
      # @raise [ArgumentError] if nil or empty +key+
      def plist_read(key, file, opts={})
        if key.nil? or key.length == 0
          raise(ArgumentError, "key '#{key}' must not be nil or empty")
        end
        cmd = build_plist_cmd(:print, {:key => key}, file)
        res = execute_plist_cmd(cmd, opts)
        if res == "Print: Entry, \":#{key}\", Does Not Exist"
          nil
        else
          res
        end
      end

      # checks if the key exists in plist
      # @param [String] key the key to inspect (may not be nil or empty)
      # @param [String] file the plist to read
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [Boolean] true iff the +key+ exists in plist +file+
      def plist_key_exists?(key, file, opts={})
        plist_read(key, file, opts) != nil

      end

      # replaces or creates the +value+ of +key+ in the +file+
      #
      # @param [String] key the key to set (may not be nil or empty)
      # @param [String] type the plist type (used only when adding a value)
      # @param [String] value the new value
      # @param [String] file the plist to read
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [Boolean] true iff the operation was successful
      # @raise [ArgumentError] if nil or empty +key+
      def plist_set(key, type, value, file, opts={})
        default_opts = {:verbose => false}
        merged = default_opts.merge(opts)

        if key.nil? or key.length == 0
          raise(ArgumentError, "key '#{key}' must not be nil or empty")
        end

        cmd_args = {:key => key,
                    :type => type,
                    :value => value}

        if plist_key_exists?(key, file, merged)
          cmd = build_plist_cmd(:set, cmd_args, file)
        else
          cmd = build_plist_cmd(:add, cmd_args, file)
        end

        res = execute_plist_cmd(cmd, merged)
        res == ''
      end

      @private

      # returns the path to the PlistBuddy executable
      # @return [String] path to PlistBuddy
      def plist_buddy
        '/usr/libexec/PlistBuddy'
      end

      # executes +cmd+ as a shell command and returns the result
      #
      # @param [String] cmd shell command to execute
      # @param [Hash] opts options for controlling execution
      # @option opts [Boolean] :verbose (false) controls log level
      # @return [Boolean] if command was successful
      # @return [String] if :print'ing result, the value of the key
      # @return [String] if there is an error, the output from stderr
      def execute_plist_cmd(cmd, opts={})
        default_opts = {:verbose => false}
        merged = default_opts.merge(opts)

        calabash_info(cmd) if merged[:verbose]

        res = nil
        # noinspection RubyUnusedLocalVariable
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          err = stderr.read
          std = stdout.read
          if not err.nil? and err != ''
            res = err.chomp
          else
            res = std.chomp
          end
        end
        res
      end

      # composes a PlistBuddy command that can be executed as a shell command
      #
      # @param [Symbol] type should be one of [:print, :set, :add]
      #
      # @param [Hash] args_hash arguments used to construct plist command
      # @option args_hash [String] :key (required) the plist key
      # @option args_hash [String] :value (required for :set and :add) the new value
      # @option args_hash [String] :type (required for :add) the new type of the value
      #
      # @param [String] file the plist file to interact with (must exist)
      #
      # @raise [RuntimeError] if +file+ does not exist
      # @raise [ArgumentError] when invalid +type+ is passed
      # @raise [ArgumentError] when +args_hash+ does not include required key/value pairs
      #
      # @return [String] a shell-ready PlistBuddy command
      def build_plist_cmd(type, args_hash, file)

        unless File.exist?(File.expand_path(file))
          raise(RuntimeError, "plist '#{file}' does not exist - could not read")
        end

        case type
          when :add
            value_type = args_hash[:type]
            unless value_type
              raise(ArgumentError, ':value_type is a required key for :add command')
            end
            allowed_value_types = ['string', 'bool', 'real', 'integer']
            unless allowed_value_types.include?(value_type)
              raise(ArgumentError, "expected '#{value_type}' to be one of '#{allowed_value_types}'")
            end
            value = args_hash[:value]
            unless value
              raise(ArgumentError, ':value is a required key for :add command')
            end
            key = args_hash[:key]
            unless key
              raise(ArgumentError, ':key is a required key for :add command')
            end
            cmd_part = "\"Add :#{key} #{value_type} #{value}\""
          when :print
            key = args_hash[:key]
            unless key
              raise(ArgumentError, ':key is a required key for :print command')
            end
            cmd_part = "\"Print :#{key}\""
          when :set
            value = args_hash[:value]
            unless value
              raise(ArgumentError, ':value is a required key for :set command')
            end
            key = args_hash[:key]
            unless key
              raise(ArgumentError, ':key is a required key for :set command')
            end
            cmd_part = "\"Set :#{key} #{value}\""
          else
            cmds = [:add, :print, :set]
            raise(ArgumentError, "expected '#{type}' to be one of '#{cmds}'")
        end

        "#{plist_buddy} -c #{cmd_part} \"#{file}\""
      end

    end
  end
end