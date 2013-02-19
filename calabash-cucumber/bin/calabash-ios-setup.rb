require "calabash-cucumber/version"
require 'rexml/rexml'
require "rexml/document"


def detect_accessibility_support
  dirs = Dir.glob(File.join(File.expand_path("~/Library"),"Application Support","iPhone Simulator","*.*","Library","Preferences"))
  dirs.each do |sim_pref_dir|
    fp = File.expand_path("#{sim_pref_dir}/com.apple.Accessibility.plist")
    out = `defaults read "#{fp}" ApplicationAccessibilityEnabled`

    if not(File.exists?(fp)) || out.split("\n")[0] == "0"
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
  if res==""
    puts "Xcode not running."
    project_name, project_path, xpath = find_project_files(args)
    setup_project(project_name, project_path, xpath)

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

  else
    puts "Xcode is running. We'll be changing the project file so we'd better stop it."
    puts "Please stop XCode and run setup again"
    exit(0)
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
      zip_file = "calabash.framework-#{ENV['FRAMEWORK_VERSION']||Calabash::Cucumber::FRAMEWORK_VERSION}.zip"
      puts "Did not find calabash.framework. I'll download it...'"
      puts "http://cloud.github.com/downloads/calabash/calabash-ios/#{zip_file}"
      require 'uri'

      uri = URI.parse "http://cloud.github.com/downloads/calabash/calabash-ios/#{zip_file}"
      success = false
      if has_proxy?
        proxy_url = proxy
        connection = Net::HTTP::Proxy(proxy_url[0], proxy_url[1])
      else
        connection = Net::HTTP
      end
      begin
      connection.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri

        http.request request do |response|
          if response.code == '200'
            open zip_file, 'wb' do |io|
              response.read_body do |chunk|
                print "."
                io.write chunk
              end
            end
            success = true
          else
             puts "Got bad response code #{response.code}."
             puts "Aborting..."
          end
        end
      end
      rescue SocketError => e
        msg("Error") do
          puts "Exception: #{e}"
          puts "Unable to download Calabash. Please check connection."
        end
        exit 1
      end
      if success
        puts "\nDownload done: #{file}. Unzipping..."
        if not system("unzip -C -K -o -q -d #{project_path} #{zip_file} -x __MACOSX/* calabash.framework/.DS_Store")
          msg("Error") do
            puts "Unable to unzip file: #{zip_file}"
            puts "You must install manually."
          end
          exit 1
        end
        FileUtils.rm(zip_file)
      else
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

  FileUtils.cd project_path do
    ##Backup
    if File.exists? "#{proj_file}.bak"
      msg("Error") do
        puts "Backup file already exists. #{proj_file}.bak"
        puts "For safety, I won't overwrite this file."
        puts "You must manually move this file, if you want to"
        puts "Run calabash-ios setup again."
      end
      exit 1
    end
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



require 'calabash-cucumber/launch/simulator_helper'
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
    dd_dir = Calabash::Cucumber::SimulatorHelper.derived_data_dir_for_project
      if not dd_dir
        puts "Unable to find iOS project."
        puts "You should run this command from an iOS project directory."
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
    app = app_dir.split(".")[0]
    res = `otool "#{File.expand_path(dir)}/Payload/#{app_dir}/#{app}" -o 2> /dev/null | grep CalabashServer`
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