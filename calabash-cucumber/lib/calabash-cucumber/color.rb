module Calabash
  # @!visibility private
  module Color
    # @!visibility private
    def self.colorize(string, color)
      "\e[#{color}m#{string}\e[0m"
    end

    # @!visibility private
    def self.red(string)
      colorize(string, 31)
    end

    # @!visibility private
    def self.green(string)
      colorize(string, 32)
    end

    # @!visibility private
    def self.yellow(string)
      colorize(string, 33)
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
  end
end