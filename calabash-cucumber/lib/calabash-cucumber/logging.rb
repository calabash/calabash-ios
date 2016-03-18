module Calabash
  module Cucumber
    require "fileutils"
    require "run_loop"
    require "calabash-cucumber/dot_dir"

    # !@visibility private
    def self.log_to_file(message)
      timestamp = self.timestamp

      begin
        File.open(self.calabash_log_file, "a:UTF-8") do |file|
          message.split($-0).each do |line|
            file.write("#{timestamp} #{line}#{$-0}")
          end
        end
      rescue => e
        message =
          %Q{Could not write:

#{message}

to calabash.log because:

#{e}
}
        RunLoop.log_debug(message)
      end
    end

    private

    # @!visibility private
    def self.timestamp
      Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    end

    # @!visibility private
    def self.logs_directory
      path = File.join(Calabash::Cucumber::DotDir.directory, "logs")
      FileUtils.mkdir_p(path)
      path
    end

    # @!visibility private
    def self.calabash_log_file
      path = File.join(self.logs_directory, "calabash.log")
      if !File.exist?(path)
        FileUtils.touch(path)
      end
      path
    end
  end
end
