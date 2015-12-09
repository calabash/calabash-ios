module Calabash
  module Cucumber

    require "fileutils"
    require "securerandom"

    # Users preferences persisted across runs:
    #
    # ~/.calabash/preferences/preferences.json
    class Preferences

      def initialize
        dot_dir = Calabash::Cucumber::DotDir.directory
        @path = File.join(dot_dir, "preferences", "preferences.json")
      end

      def to_s
        puts "Preferences:"
        ap read
      end

      def inspect
        to_s
      end

      # !@visibility private
      def usage_tracking
        preferences = read

        unless valid_user_tracking_value?(preferences[:usage_tracking])
          log_defaults_reset
          preferences[:usage_tracking] = defaults[:usage_tracking]
          write(preferences)
        end

        preferences[:usage_tracking]
      end

      # !@visibility private
      def usage_tracking=(value)
        if !valid_user_tracking_value?(value)
          raise ArgumentError,
            "Expected '#{value}' to be one of #{VALID_USAGE_TRACKING_VALUES.join(", ")}"
        end

        preferences = read
        preferences[:usage_tracking] = value
        write(preferences)
      end

      # !@visibility private
      def user_id
        preferences = read

        unless valid_user_id?(preferences[:user_id])
          preferences[:user_id] = SecureRandom.uuid
          write(preferences)
        end

        preferences[:user_id]
      end

      # !@visibility private
      def user_id=(value)
        if !valid_user_id?(value)
          raise ArgumentError,
            "Expected '#{value}' to not be nil and not an empty string"
        end

        preferences = read
        preferences[:user_id] = value
        write(preferences)
      end

      private

      # @!visibility private
      def valid_user_tracking_value?(value)
        VALID_USAGE_TRACKING_VALUES.include?(value)
      end

      # @!visibility private
      def valid_user_id?(value)
        !value.nil? && value != "" && value.is_a?(String)
      end

      # @!visibility private
      #
      # The preferences version
      VERSION = "1.0"

      # @!visibility private
      #
      # Ordered by permissiveness left to right ascending.
      #
      # "system_info" implies that "events" are also allowed.
      VALID_USAGE_TRACKING_VALUES = ["none", "events", "system_info"]

      # @!visibility private
      def version
        read[:version]
      end

      # @!visibility private
      attr_reader :path

      # @!visibility private
      def ensure_preferences_dir
        dir = File.dirname(@path)
        unless File.exist?(dir)
          FileUtils.mkdir_p(dir)
        end
      end

      # @!visibility private
      def defaults
        {
          :version => VERSION,
          :usage_tracking => "system_info",
          :user_id => SecureRandom.uuid
        }
      end

      # @!visibility private
      def write(hash)
        if hash.nil?
          raise ArgumentError, "Hash to write cannot be nil"
        end

        if !hash.is_a?(Hash)
          raise ArgumentError, "Expected a Hash argument"
        end

        if hash.count == 0
          raise ArgumentError, "Hash to write cannot be empty"
        end

        string = generate_json(hash)

        ensure_preferences_dir

        File.open(path, "w:UTF-8") do |file|
          file.write(string)
        end

        true
      end

      # @!visibility private
      def generate_json(hash)
        begin
          JSON.pretty_generate(hash)
        rescue TypeError, JSON::UnparserError => e
          write_to_log(
%Q{Error generating JSON from:
 hash: #{hash}
error: #{e}
})
          log_defaults_reset

          # Will always generate valid JSON
          generate_json(defaults)
        end
      end

      # @!visibility private
      def read
        if File.exist?(path)

          string = File.read(path).force_encoding("UTF-8")

          parse_json(string)
        else
          hash = defaults
          write(hash)
          hash
        end
      end

      # @!visibility private
      def parse_json(string)
        begin
          JSON.parse(string, {:symbolize_names => true})
        rescue TypeError, JSON::ParserError => e
          write_to_log(
%Q{Error parsing JSON from:
string: #{string}
 error: #{e}
})
          log_defaults_reset

          hash = defaults
          write(hash)
          hash
        end
      end

      # @!visibility private
      def write_to_log(error_message)
        # TODO write to a log file?
      end

      # @!visibility private
      def log_defaults_reset
        Calabash::Cucumber.log_warn(
%q{An error occurred while accessing your user preferences.

We have reset the preferences to the default settings.

If this happens on a regular basis, please create a GitHub issue.

Your preferences control various Calabash behaviors.  In particular, they tell
us how much usage information you are willing to share.  If you have previously
turned off usage tracking, you will need to disable it again using the command
line tools or the irb.

We do not recommend that edit the preferences file by hand.
})
      end
    end
  end
end

