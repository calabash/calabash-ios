require 'sim_launcher'

def quit_sim
  `echo 'application "iPhone Simulator" quit' | osascript`
end
def calabash_sim_reset
  reset_script = File.absolute_path("#{@script_dir}/reset_simulator.scpt")
  launcher = SimLauncher::Simulator.new
  sdks = SimLauncher::SdkDetector.new(launcher).available_sdk_versions
  sdks.each do |sdk_path_str|
    launcher.launch_ios_app("DUMMY_APP",sdk_path_str,"ipad")
    system("osascript #{reset_script}")
    launcher.launch_ios_app("DUMMY_APP",sdk_path_str,"iphone")
    system("osascript #{reset_script}")
  end

  quit_sim

end

def calabash_sim_accessibility
  dirs = Dir.glob(File.join(File.expand_path("~/Library"),"Application Support","iPhone Simulator","*.*","Library","Preferences"))
  dirs.each do |sim_pref_dir|
    fp = File.absolute_path("#{@script_dir}/data/")
    FileUtils.cp("#{fp}/com.apple.Accessibility.plist", sim_pref_dir)
  end
end

def calabash_sim_locale(args)

  prefs_path = File.absolute_path("#{@script_dir}/data/.GlobalPreferences.plist")
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
  lang_index = langs.find_index {|l| l == lang}

  if lang_index.nil?
    puts "Unable to find #{lang}..."
    puts "Options:\n#{langs.join("\n")}"
    exit 0
  end

  langs[0],langs[lang_index] = langs[lang_index],langs[0]


  if reg
    hash['AppleLocale'] = reg
  end
  res_plist = CFPropertyList::List.new
  res_plist.value = CFPropertyList.guess(hash)
  dirs = Dir.glob(File.join(File.expand_path("~/Library"),"Application Support","iPhone Simulator","*.*","Library","Preferences"))
  dirs.each do |sim_pref_dir|
    res_plist.save("#{sim_pref_dir}/.GlobalPreferences.plist", CFPropertyList::List::FORMAT_BINARY)
  end


end


def calabash_sim_device(args)
  quit_sim
  options = ["iPad", "iPhone", "iPhone_Retina"]
  if args.length != 1 or not options.find {|x| x == args[0]}
    print_usage
    puts "Unrecognized args: #{args}"
    puts "should be one of #{options}"
    exit(0)
  end
  path =File.join(File.expand_path("~/Library"),"Preferences","com.apple.iphonesimulator.plist")
  plist = CFPropertyList::List.new(:file => path)
  hash = CFPropertyList.native_types(plist.value)
  hash['SimulateDevice'] = args[0].gsub("iPhone_Retina","iPhone (Retina)")
  plist.value = CFPropertyList.guess(hash)
  plist.save(path, CFPropertyList::List::FORMAT_BINARY)
end

