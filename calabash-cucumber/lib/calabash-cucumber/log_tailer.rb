
module Calabash
  module Cucumber
    class LogTailer

      # @!visibility private
      def self.tail_in_terminal(path)
        if !File.exist?(path)
          raise RuntimeError, %Q[
Cannot tail a file that does not exist:

#{path}

]
        end

        term_part = %Q[xcrun osascript -e 'tell application "Terminal" to do script]
        tail_part = %Q["tail -n 10000 -F #{path} | grep -v \\"Default: \\\\*\\""']
        cmd = "#{term_part} #{tail_part}"

        if !LogTailer.run_command(cmd)
          raise RuntimeError, %Q[
Could not tail file:

#{path}

with command:

#{cmd}

]
        end

        true
      end

      private

      # @!visibility private
      def self.run_command(cmd)
        system(cmd)
      end
    end
  end
end
