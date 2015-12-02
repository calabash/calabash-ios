module Calabash
  module Cucumber

    require "fileutils"

    # Users preferences persisted across runs:
    #
    # ~/.calabash/preferences/preferences.json
    class Preferences

      def initialize
        dot_dir = Calabash::Cucumber::DotDir.directory
        @path = File.join(dot_dir, "preferences", "preferences.json")
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
      end

      private

      # @!visibility private
      def valid_user_tracking_value?(value)
        VALID_USAGE_TRACKING_VALUES.include?(value)
      end

      # @!visibility private
      def ensure_valid_user_tracking_value?(value)
        unless valid_user_tracking_value?(value)
          log_defaults_reset
          preferences[:usage_tracking] = defaults[:usage_tracking]
          write(preferences)
        end
      end

      # @!visibility private
      #
      # The preferences version
      VERSION = "1.0"

      # @!visibility private
      #
      # Ordered by permissiveness left to right ascending.
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

          # Controls what information we are allowed to track.
          #
          # If this is "none", then no information is sent.
          #
          # Allowed values:
          #
          # 1. "none"
          # 2. "events"  Events only.
          # 3. "system_info"  Events and system info
          #
          # The value must be string and it must respond nicely to .to_sym
          :usage_tracking => "system_info"
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

