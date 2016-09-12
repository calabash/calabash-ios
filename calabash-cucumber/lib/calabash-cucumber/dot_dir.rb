module Calabash
  module Cucumber
    # A module for managing the ~/.calabash directory.
    module DotDir
      require "run_loop"

      # @!visibility private
      def self.directory
        home = RunLoop::Environment.user_home_directory
        dir = File.join(home, ".calabash")
        if !File.exist?(dir)
          FileUtils.mkdir_p(dir)
        end
        dir
      end
    end
  end
end

