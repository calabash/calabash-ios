module Calabash
  module Cucumber
    module Dylibs

      def self.sim_dylib_basename
        "libCalabashDynSim.dylib"
      end

      def self.path_to_sim_dylib
        File.join(self.dylib_dir, self.sim_dylib_basename)
      end

      def self.device_dylib_basename
        "libCalabashDyn.dylib"
      end

      def self.path_to_device_dylib
        File.join(self.dylib_dir, self.device_dylib_basename)
      end

      private

      def self.dylib_dir
        dirname = File.dirname(__FILE__)
        File.expand_path(File.join(dirname, "..", "..", "dylibs"))
      end
    end
  end
end
