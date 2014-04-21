require 'sim_launcher'
require 'calabash-cucumber/launch/simulator_helper'

def quit_sim
  `echo 'application "iPhone Simulator" quit' | osascript`
end

def calabash_sim_reset
  reset_script = File.expand_path("#{@script_dir}/reset_simulator.scpt")
  app_path = File.expand_path("#{@script_dir}/EmptyAppHack.app")
  launcher = SimLauncher::Simulator.new

  sdks = ENV['SDK_VERSIONS']
  if sdks
    sdks = sdks.split(",")
  else
    sdks = SimLauncher::SdkDetector.new(launcher).available_sdk_versions
  end


  sdks.each do |sdk|
    launcher.launch_ios_app(app_path, sdk, ENV['DEVICE'] || 'iphone')
    puts `osascript #{reset_script}`
  end


end

def calabash_sim_accessibility
  Calabash::Cucumber::SimulatorHelper.stop
  old = ['5.*','6.*','7.0*'].map do |x|
    Dir.glob(File.join(File.expand_path("~/Library"), "Application Support", "iPhone Simulator", "7.0*", "Library", "Preferences"))
  end.flatten

  rest = Dir.glob(File.join(File.expand_path("~/Library"), "Application Support", "iPhone Simulator", "*.*", "Library", "Preferences"))
  rest = rest - old
  (old+rest).each do |sim_pref_dir|
    fp = File.expand_path("#{@script_dir}/data/")
    if rest.include?(sim_pref_dir)
      tgt = 'com.apple.Accessibility-5.1.plist'
    else
      tgt = 'com.apple.Accessibility.plist'
    end
    FileUtils.cp("#{fp}/#{tgt}", File.join(sim_pref_dir, 'com.apple.Accessibility.plist'))
  end

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
  quit_sim
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
