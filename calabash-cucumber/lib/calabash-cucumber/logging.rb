module Calabash
  module Cucumber
    require "run_loop"

    # These methods are not part of the API.
    #
    # They may change at any time.

    # !@visibility private
    # blue
    def self.log_warn(msg)
      puts self.blue(" WARN: #{msg}") if msg
    end

    # !@visibility private
    # magenta
    def self.log_debug(msg)
      if RunLoop::Environment.debug?
        puts self.magenta("DEBUG: #{msg}") if msg
      end
    end

    # !@visibility private
    # green
    def self.log_info(msg)
      puts self.green(" INFO: #{msg}") if msg
    end

    # !@visibility private
    # red
    def self.log_error(msg)
      puts self.red("ERROR: #{msg}") if msg
    end

    private

    # @!visibility private
    def self.windows_env?
      RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
    end

    # @!visibility private
    def self.colorize(string, color)
      if self.windows_env?
        string
      elsif RunLoop::Environment.xtc?
        string
      else
        "\033[#{color}m#{string}\033[0m"
      end
    end

    # @!visibility private
    def self.red(string)
      colorize(string, 31)
    end

    # @!visibility private
    def self.blue(string)
      colorize(string, 34)
    end

    # @!visibility private
    def self.magenta(string)
      colorize(string, 35)
    end

    # @!visibility private
    def self.cyan(string)
      colorize(string, 36)
    end

    # @!visibility private
    def self.green(string)
      colorize(string, 32)
    end
  end
end

