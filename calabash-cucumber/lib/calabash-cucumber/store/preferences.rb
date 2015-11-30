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

        dir = File.dirname(@path)
        unless File.exist?(dir)
          FileUtils.mkdir_p(dir)
        end

        unless File.exist?(@path)
          FileUtils.touch(@path)
        end
      end

      private

      # @!visibility private
      attr_reader :path

      # @!visibility private
      def defaults
        {
          :usage_tracking =>
          {

          }
        }
      end

    end
  end
end
