module Calabash
  module Cucumber
    class Preferences < Calabash::Cucumber::Cache

      private

      # @!visibility private
      PATH = File.join(Calabash::Cucumber::DotDir.directory,
                       "preferences", "preferences.hash")

      # @!visibility private
      @@preferences = nil

      # @!visibility private
      def self.preferences
        @@preferences ||= Calabash::Cucumber::Preferences.new(PATH)
      end
    end
  end
end

