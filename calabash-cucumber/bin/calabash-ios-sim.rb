require 'calabash-cucumber/utils/simulator_accessibility'
require 'calabash-cucumber/utils/logging'

include Calabash::Cucumber::Logging
include Calabash::Cucumber::SimulatorAccessibility

def quit_sim
  _deprecated('0.9.169', 'use Calabash::Cucumber::SimulatorAccessibility.quit_simulator', :warn)
  quit_simulator
end

def calabash_sim_reset
  reset_simulator_content_and_settings
end

def calabash_sim_accessibility
  enable_accessibility_on_simulators
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

  prefs_path = File.expand_path("#{@script_dir}/data/.GlobalPreferences.plist")
  plist = CFPropertyList::List.new(:file => prefs_path)
  hash = CFPropertyList.native_types(plist.value)


  if args.length == 0
    print_usage
    puts "Options: \n"
    puts hash['AppleLanguages'].join("\n")
    exit 0
  end
  lang = args.shift
  reg = nil
  if args.length == 1
    reg = args.shift
  end

  langs = hash['AppleLanguages']
  lang_index = langs.find_index { |l| l == lang }

  if lang_index.nil?
    puts "Unable to find #{lang}..."
    puts "Options:\n#{langs.join("\n")}"
    exit 0
  end

  langs[0], langs[lang_index] = langs[lang_index], langs[0]


  if reg
    hash['AppleLocale'] = reg
  end
  res_plist = CFPropertyList::List.new
  res_plist.value = CFPropertyList.guess(hash)
  dirs = Dir.glob(File.join(File.expand_path("~/Library"), "Application Support", "iPhone Simulator", "*.*", "Library", "Preferences"))
  dirs.each do |sim_pref_dir|
    res_plist.save("#{sim_pref_dir}/.GlobalPreferences.plist", CFPropertyList::List::FORMAT_BINARY)
  end


end


def calabash_sim_device(args)
  quit_simulator
  options = ["iPad", "iPad_Retina", "iPhone", "iPhone_Retina", "iPhone_Retina_4inch"]
  if args.length != 1 or not options.find { |x| x == args[0] }
    print_usage
    puts "Unrecognized args: #{args}"
    puts "should be one of #{options.inspect}"
    exit(0)
  end
  path =File.join(File.expand_path("~/Library"), "Preferences", "com.apple.iphonesimulator.plist")
  plist = CFPropertyList::List.new(:file => path)
  hash = CFPropertyList.native_types(plist.value)

  device = case args[0]
             when "iPad_Retina"
               "iPad (Retina)"
             when "iPhone_Retina"
               "iPhone (Retina 3.5-inch)"
             when "iPhone_Retina_4inch"
               "iPhone (Retina 4-inch)"
             else
               args[0]
           end
  if device
    hash['SimulateDevice'] = device
    plist.value = CFPropertyList.guess(hash)
    plist.save(path, CFPropertyList::List::FORMAT_BINARY)
  end

end
