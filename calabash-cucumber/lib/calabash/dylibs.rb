module Calabash
  module Dylibs
    def sim_dylib_basename
      'libCalabashDynSim.dylib'
    end

    def path_to_sim_dylib
      File.expand_path File.join(__FILE__, '..', '..', '..', 'dylibs', sim_dylib_basename)
    end

    def device_dylib_basename
      'libCalabashDyn.dylib'
    end

    def path_to_device_dylib
      File.expand_path File.join(__FILE__, '..', '..', '..', 'dylibs', device_dylib_basename)
    end

    module_function :path_to_sim_dylib, :path_to_device_dylib, :device_dylib_basename, :sim_dylib_basename
  end
end
