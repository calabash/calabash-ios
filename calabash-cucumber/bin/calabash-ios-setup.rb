require "calabash-cucumber/version"
require 'rexml/rexml'
require "rexml/document"


def detect_accessibility_support
  dirs = Dir.glob(File.join(File.expand_path("~/Library"),"Application Support","iPhone Simulator","*.*","Library","Preferences"))
  dirs.each do |sim_pref_dir|
    fp = File.expand_path("#{sim_pref_dir}/com.apple.Accessibility.plist")
    out = `defaults read "#{fp}" AXInspectorEnabled`
    ax_inspector = out.split("\n")[0]=="0"
    out = `defaults read "#{fp}" ApplicationAccessibilityEnabled`
    app_acc = out.split("\n")[0]=="0"
    if not(File.exists?(fp)) || ax_inspector == "0" || app_acc == "0"
        msg("Warn") do
          puts "Accessibility is not enabled for simulator: #{sim_pref_dir}"
          puts "Enabled accessibility as described here:"
          puts "https://github.com/calabash/calabash-ios/wiki/01-Getting-started-guide"
          puts "Alternatively run command:"
          puts "calabash-ios sim acc"
        end
    end

  end
end

def calabash_setup(args)
  puts "Checking if Xcode is running..."
  res = `ps x -o pid,command | grep -v grep | grep Contents/MacOS/Xcode`
  unless res==""
    puts "Detected running Xcode. You may need to restart Xcode after setup."
  end

  project_name, project_path, xpath = find_project_files(args)
  setup_project(project_name, project_path, xpath)

  calabash_sim_accessibility
  detect_accessibility_support

  msg("Setup done") do

    puts "Please validate by running the -cal target"
    puts "from Xcode."
    puts "When starting the iOS Simulator using the"
    puts "new -cal target, you should see:\n\n"
    puts '  "Started LPHTTP server on port 37265"'
    puts "\nin the application log in Xcode."
    puts "\n\n"
    puts "After validating, you can generate a features folder:"
    puts "Go to your project (the dir containing the .xcodeproj file)."
    puts "Then run calabash-ios gen"
    puts "(if you don't already have a features folder)."
  end
end

def find_project_files(args)
  dir_to_search, project_files = ensure_correct_path(args)

  xc_project_file = project_files[0]
  project_name = xc_project_file.split(".xcodeproj")[0]
  puts "Found Project: #{project_name}"
  pbx_dir = "#{dir_to_search}/#{xc_project_file}"
  pbx_files = Dir.foreach(pbx_dir).find_all { |x| /\.pbxproj$/.match(x) }
  if pbx_files.empty?
    puts "Found no *.pbxproj files in dir #{xc_project_file}."
    puts "Please setup calabash manually."
    exit 1
  elsif pbx_files.count > 1
    puts "Found several *.pbxproj files in dir #{xc_project_file}."
    puts "Found: #{pbx_files.join("\n")}"
    puts "We don't yet support this. Please setup calabash manually."
    exit 1
  end

  return project_name, dir_to_search, File.expand_path("#{dir_to_search}/#{xc_project_file}")
end

def calabash_download(args)
  download_calabash(File.expand_path("."))
end

def has_proxy?
  ENV['http_proxy'] ? true : false
end

def proxy
  url_parts = URI.split(ENV['http_proxy'])
  [url_parts[2], url_parts[3]]
end

def download_calabash(project_path)
  file = 'calabash.framework'
  ##Download calabash.framework
  if not File.directory?(File.join(project_path, file))
    msg("Info") do
      zip_file = File.join(@framework_dir,"calabash.framework.zip")

      if File.exist?(zip_file)
        if not system("unzip -C -K -o -q -d '#{project_path}' '#{zip_file}' -x __MACOSX/* calabash.framework/.DS_Store")
          msg("Error") do
            puts "Unable to unzip file: #{zip_file}"
            puts "You must install manually."
          end
          exit 1
        end
      else
        puts "Inconsistent gem state: Cannot find framework: #{zip_file}"
        exit 0
      end
    end
  else
    msg("Info") do
      puts "Found calabash.framework in #{File.expand_path(project_path)}."
      puts "Shall I delete it and download the latest matching version?"
      puts "Please answer yes (y) or no (n)"
      answer = STDIN.gets.chomp
      if (answer == 'yes' or answer == 'y')
        FileUtils.rm_r File.join(project_path, file)
        return download_calabash(project_path)
      else
        puts "Not downloading..."
      end
    end
  end
  file
end

def setup_project(project_name, project_path, path)
  ##Ensure exists and parse
  proj_file = "#{path}/project.pbxproj"
  if not File.exists?(proj_file)
    msg("Error") do
      puts "Directory #{path} doesn't contain #{proj_file}"
    end
    exit 1
  end

  download_calabash(project_path)

  msg("Info") do
    puts "Setting up project file for calabash-ios."
  end

  ##Backup
  msg("Info") do
    puts "Making backup of project file: #{proj_file}"
    FileUtils.cp(proj_file, "#{proj_file}.bak")
    puts "Saved as #{proj_file}.bak"
  end

  path_to_setup = File.join(File.dirname(__FILE__), 'CalabashSetup')
  setup_cmd = %Q[#{path_to_setup} "#{path}" "#{project_name}"]
  system(setup_cmd)

end

require 'calabash-cucumber/launch/simulator_launcher'
def validate_setup(args)
  if args.length > 0
    if args[0].end_with?(".ipa")
      validate_ipa(args[0])
    elsif args[0].end_with?(".app")
      validate_app(args[0])
    else
      msg("Error") do
        puts "File should end with .app or .ipa"
      end
      exit 1
    end
  else
    dd_dir = Calabash::Cucumber::SimulatorLauncher.new().derived_data_dir_for_project
      if not dd_dir
        puts "Unable to find iOS XCode project."
        puts "You should run this command from an XCode project directory."
        exit 1
      end
      app_bundles = Dir.glob(File.join(dd_dir, "Build", "Products", "*", "*.app"))
      sim_dirs = Dir.glob(File.join(dd_dir, "Build", "Products", "Debug-iphonesimulator", "*.app"))
      sim_dirs = sim_dirs.concat(Dir.glob(File.join(dd_dir, "Build", "Products", "Calabash-iphonesimulator", "*.app")))
      if sim_dirs.empty?
        msg = ["Have you built your app for simulator?"]
        msg << "You should build the -cal target and your normal target"
        msg << "(with configuration Debug)."
        msg << "Searched dir: #{dd_dir}/Build/Products"
        msg("Error") do
          puts msg.join("\n")
        end
        exit 1
      elsif sim_dirs.count != 2
        msg = ["Have you built your app for simulator?"]
        msg << "You should build the -cal target and your normal target"
        msg << "(with configuration Debug)."
        msg << "Searched dir: #{dd_dir}/Build/Products"
        msg("Error") do
          puts msg.join("\n")
        end
        exit 1
      end
      out_debug = `otool "#{sim_dirs[0]}"/* -o 2> /dev/null | grep CalabashServer`
      out_cal = `otool "#{sim_dirs[1]}"/* -o 2> /dev/null | grep CalabashServer 2> /dev/null`
      ok = (not /CalabashServer/.match(out_debug)) and /CalabashServer/.match(out_cal)
      if ok
        msg("OK") do
          puts "Your configuration seems ok."
          puts "app in directory:"
          puts sim_dirs[0]
          puts "does not have calabash.framework linked in."
          puts "directory:"
          puts sim_dirs[1]
          puts "does."
        end
      else
        msg("Fail") do
          puts "Your configuration looks bad."
          if (not /CalabashServer/.match(out_debug))
            puts "WARNING: You Debug build seems to be linking with Calabash."
            puts "You should restore your xcodeproject file from backup."
          else
            puts "app in directory"
            puts sim_dirs[1]
            puts "does not have calabash.framework linked in."
          end
        end
      end
  end


end

def validate_ipa(ipa)
  require 'tmpdir'
  fail = false
  Dir.mktmpdir do |dir|
    if not system("unzip -C -K -o -q -d #{dir} #{ipa}")
      msg("Error") do
        puts "Unable to unzip ipa: #{ipa}"
      end
      Dir
      fail = true
    end

    app_dir = Dir.foreach("#{dir}/Payload").find {|d| /\.app$/.match(d)}

    res = `otool "#{File.expand_path(dir)}/Payload/#{app_dir}/"* -o 2> /dev/null | grep CalabashServer`
    msg("Info") do
      if /CalabashServer/.match(res)
        puts "Ipa: #{ipa} *contains* calabash.framework"
      else
        puts "Ipa: #{ipa} *does not contain* calabash.framework"
      end
    end

  end
  if fail 
    exit(1)
  end
  
end

def validate_app(app)
  if not File.directory?app
    msg("Error") do
      puts "Path: #{app} is not a directory."
    end
    exit 1
  end
  out = `otool "#{File.expand_path(app)}"/* -o 2> /dev/null | grep CalabashServer`

  msg("Info") do
    if /CalabashServer/.match(out)
      puts "App: #{app} *contains* calabash.framework"
    else
      puts "App: #{app} *does not contain* calabash.framework"
    end
  end

end


def update(args)
  if args.length > 0
    target = args[0]
    unless UPDATE_TARGETS.include?(target)
      msg('Error') do
        puts "Invalid target #{target}. Must be one of: #{UPDATE_TARGETS.join(' ')}"
      end
      exit 1
    end



    target_file = 'features/support/launch.rb'
    msg('Question') do
      puts "I'm about to update the #{target_file} file."
      puts "Please hit return to confirm that's what you want."
    end
    exit 2 unless STDIN.gets.chomp == ''


    unless File.exist?(target_file)
      msg('Error') do
        puts "Unable to find file #{target_file}"
        puts "Please change directory so that #{target_file} exists."
      end
      exit 1
    end
    new_launch_script = File.join(@script_dir, 'launch.rb')

    FileUtils.cp(new_launch_script, 'features/support/01_launch.rb', :verbose => true)
    FileUtils.rm(target_file, :force => true, :verbose => true)

    hooks_file = 'features/support/hooks.rb'
    if File.exist?(hooks_file)
      FileUtils.mv(hooks_file, 'features/support/02_pre_stop_hooks.rb', :verbose => true)
    end

    msg('Info') do
      puts "File copied.\n"
      puts 'Launch on device using environment variable DEVICE_TARGET=device.'
      puts 'Launch on simulator by default or using environment variable DEVICE_TARGET=simulator.'
    end
  else
    msg('Error') do
      puts "update must take one of the following targets: #{UPDATE_TARGETS.join(' ')}"
    end
    exit 1

  end

end