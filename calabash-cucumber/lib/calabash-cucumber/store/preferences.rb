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

      private

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
          :usage_tracking =>
          {

          }
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

      # @!visibilit private
      def log_defaults_reset
        # TODO Tell the user their preferences have been overwritten
      end
    end
  end
end

