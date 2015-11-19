# A module for managing the ~/.calabash directory.
module Calabash
  module DotDir
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

