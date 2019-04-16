module Calabash
  module Cucumber

    # @!visibility private
    module Dylibs

      # @!visibility private
      def self.sim_dylib_basename
        "libCalabashSim.dylib"
      end

      # @!visibility private
      def self.path_to_sim_dylib
        File.join(self.dylib_dir, self.sim_dylib_basename)
      end

      # @!visibility private
      def self.device_dylib_basename
        "libCalabashARM.dylib"
      end

      # @!visibility private
      def self.path_to_device_dylib
        File.join(self.dylib_dir, self.device_dylib_basename)
      end

      private

      # @!visibility private
      def self.dylib_dir
        dirname = File.dirname(__FILE__)
        File.expand_path(File.join(dirname, "..", "..", "dylibs"))
      end
    end
  end
end

