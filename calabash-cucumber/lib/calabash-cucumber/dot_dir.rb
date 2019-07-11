module Calabash
  module Cucumber
    # A module for managing the ~/.test-cloud-dev directory.
    module DotDir
      require "run_loop"

      # @!visibility private
      def self.directory
        home = RunLoop::Environment.user_home_directory
        dir = File.join(home, ".test-cloud-dev")
        if !File.exist?(dir)
          FileUtils.mkdir_p(dir)
        end
        dir
      end
    end
  end
end

