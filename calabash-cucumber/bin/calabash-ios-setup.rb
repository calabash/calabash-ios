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

# @todo eval for deprecation - has no callers.
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
    $stderr.puts(
      %Q["Please pass a .app or .ipa as an argument.  Ad hoc validation of projects
is not yet supported])
    $stderr.flush
    exit 1
  end
end

def validate_ipa(ipa)
  begin
    version = RunLoop::Ipa.new(ipa).calabash_server_version
  rescue => e
    $stderr.puts(e.message)
    exit(1)
  end

  if version
    puts "Ipa: #{ipa} *contains* calabash.framework"
    puts version.to_s
    exit(0)
  else
    puts "Ipa: #{ipa} *does not contain* calabash.framework"
    exit(1)
  end
end

def validate_app(app)
  begin
    version = RunLoop::App.new(app).calabash_server_version
  rescue => e
    $stderr.puts(e.message)
    exit(1)
  end

  if version
    puts "App: #{app} *contains* calabash.framework"
    puts version.to_s
    exit(0)
  else
    puts "App: #{app} *does not contain* calabash.framework"
    exit(1)
  end
end
