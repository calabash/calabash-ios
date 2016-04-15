require "run_loop"

def quit_sim
  RunLoop::SimControl.new.quit_sim
end

def calabash_sim_reset
  RunLoop::SimControl.new.reset_sim_content_and_settings
end

def calabash_sim_accessibility
  RunLoop::SimControl.new.enable_accessibility_on_sims
end

def calabash_sim_location(args)

  if args.length == 0
    print_usage
    exit 0
  end
  on_off = args.shift
  if args.length == 0
    print_usage
    exit 0
  end
  bundle_id = args.shift


  dirs = Dir.glob(File.join(File.expand_path("~/Library"), "Application Support", "iPhone Simulator", "*.*", "Library", "Caches", "locationd"))
  dirs.each do |sim_dir|
    existing_path = "#{sim_dir}/clients.plist"
    if File.exist?(existing_path)
      plist_path = existing_path
    else
      plist_path = File.expand_path("#{@script_dir}/data/clients.plist")
    end

    plist = CFPropertyList::List.new(:file => plist_path)
    hash = CFPropertyList.native_types(plist.value)

    app_hash = hash[bundle_id]
    if not app_hash
      app_hash = hash[bundle_id] = {}
    end
    app_hash["BundleId"] = bundle_id
    app_hash["Authorized"] = on_off == "on" ? true : false
    app_hash["LocationTimeStarted"] = 0

    ##Plist edit the template
    res_plist = CFPropertyList::List.new
    res_plist.value = CFPropertyList.guess(hash)
    res_plist.save(existing_path, CFPropertyList::List::FORMAT_BINARY)

  end
end


def calabash_sim_locale(args)

  if args.length != 2
   puts %Q{
Usage:

$ calabash-ios sim locale < language code > < locale code >

Examples:

# French language and locale
$ calabash-ios sim locale fr fr

# Swiss French with Swiss German locale
$ calabash-ios sim locale fr-CH de_CH

By default, this method will change the default simulator for the active
Xcode version.  If you want to target an alternative simulator, set the
DEVICE_TARGET environment variable.

$ DEVICE_TARGET="iPhone 6 (9.2)" calabash-ios sim locale en-US en_US
$ DEVICE_TARGET=B9BCAD64-1624-4277-9361-40EFFBD7C67F calabash-ios sim locale de de

This operation will quit and reset the simulator.
}
   return false
  end

  language = args[0]
  locale = args[1]

  xcode = RunLoop::Xcode.new
  instruments = RunLoop::Instruments.new
  simctl = RunLoop::Simctl.new

  device = RunLoop::Device.detect_device({}, xcode, simctl, instruments)

  if device.nil?
    if RunLoop::Environment.device_target
      puts %Q{
Could not find simulator matching:

  DEVICE_TARGET=#{RunLoop::Environment.device_target}

Check the output of:

$ xcrun instruments -s devices

for a list of available simulators.
}
    else
      puts %Q{
Could not find the default simulator:

  #{RunLoop::Core.default_simulator}

1. Your Xcode version might not be compatible with run-loop #{RunLoop::VERSION}.
2. You might need to install additional simulators in Xcode.
}
    end

    return false
  end

  if device.physical_device?
    puts %Q{
This tool is for simulators only.

#{device} is a physical device.
}
    return false
  end

  RunLoop::CoreSimulator.set_language(device, language)
  RunLoop::CoreSimulator.set_locale(device, locale)

  puts %Q{
Set langauge to: '#{language}' and locale to: '#{locale}'.

Don't forget to launch your app with these options:

options = {
  args = [
           "-AppleLanguages", "(#{language})",
           "-AppleLocale", "#{locale}"
         ]
}

to ensure that your app launches with the correct primary langauge.

Examples:

* https://github.com/calabash/calabash-ios/wiki/Changing-Locale-and-Language
* https://github.com/calabash/Permissions/blob/master/features/0x/support/01_launch.rb

SUCCESS!
}
  true
end
