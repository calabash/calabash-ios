require "calabash-cucumber/version"


def dup_scheme(project_name, pbx_dir, target)

  userdata_dirs = Dir.foreach("#{pbx_dir}/xcuserdata").find_all { |x|
    /\.xcuserdatad$/.match(x)
  }

  target_name = target.name.value

  if target_name.start_with?'"' and target_name.end_with?'"'
    target_name = target_name[1..target_name.length-2]
  end

  userdata_dirs.each do |userdata_dir|
    scheme_to_find = Regexp.new(Regexp.escape("#{target_name}.xcscheme"))
    cal_scheme_to_find = Regexp.new(Regexp.escape("#{target_name}-cal.xcscheme"))
    schemes = Dir.foreach("#{pbx_dir}/xcuserdata/#{userdata_dir}/xcschemes")
    scheme = schemes.find do |scheme|
      scheme_to_find.match(scheme)
    end
    cal_scheme = schemes.find do |scheme|
      cal_scheme_to_find.match(scheme)
    end

    if scheme.nil?
      puts "-"*10 + "Warning" + "-"*10
      puts "Unable to find scheme: #{target_name}.xcscheme."
      puts "You must manually create a scheme."
      puts "Make sure your scheme uses the Calabash build configuration."
      puts "-"*10 + "-------" + "-"*10
    else
      if not cal_scheme.nil?
        msg("Warning") do
          puts "Scheme: #{target_name}-cal.xcscheme already exists."
          puts "Will not try to duplicate #{project_name}.xcscheme."
        end
      else
        msg("Action") do
          puts "Duplicating scheme #{target_name}.xcscheme as #{target_name}-cal.xcscheme"

          doc = REXML::Document.new(File.new("#{pbx_dir}/xcuserdata/#{userdata_dir}/xcschemes/#{scheme}"))

          doc.elements.each("Scheme/LaunchAction") do |la|
            la.attributes["buildConfiguration"] = "Calabash"
          end
          doc.elements.each("Scheme/ArchiveAction") do |la|
            la.attributes["buildConfiguration"] = "Calabash"
          end
          doc.elements.each("Scheme/AnalyzeAction") do |la|
            la.attributes["buildConfiguration"] = "Calabash"
          end
          doc.elements.each("Scheme/ProfileAction") do |la|
            la.attributes["buildConfiguration"] = "Calabash"
          end
          doc.write(File.open("#{pbx_dir}/xcuserdata/#{userdata_dir}/xcschemes/#{target_name}-cal.xcscheme", "w"))
        end
      end
    end

  end
  "#{target_name}-cal"
end


def calabash_setup(args)
  puts "Checking if Xcode is running..."
  res = `ps x -o pid,command | grep -v grep | grep Xcode.app/Contents/MacOS/Xcode`
  if res==""
    puts "Xcode not running."
    project_name, project_path, xpath = find_project_files(args)
    target = setup_project(project_name, project_path, xpath)
    scheme = dup_scheme(project_name, xpath, target)
    msg("Setup done") do

      puts "Please validate by running the #{scheme} scheme"
      puts "from Xcode."
      puts "When starting the iOS Simulator using the"
      puts "new scheme: #{project_name}-cal, you should see:\n\n"
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
    puts "Shall I stop Xcode? Please answer yes (y) or no (n)"
    answer = STDIN.gets.chomp
    if (answer == 'yes' or answer == 'y')
      res.split("\n").each do |line|
        pid = line.split(" ")[0]
        if system("kill #{pid}")
          puts "Stopped XCode. Retrying... "
          calabash_setup(args)
        else
          puts "Killing Xcode seemed to fail :( Aborting..."
        end
      end
    else
      puts "Please stop Xcode and try again."
      exit(0)
    end
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
  project_name, project_path, xpath = find_project_files(args)
  download_calabash(project_path)
end

def download_calabash(project_path)
  file = 'calabash.framework'
  ##Download calabash.framework
  if not Dir.exists?(File.join(project_path, file))
    msg("Info") do
      zip_file = "calabash.framework-#{ENV['FRAMEWORK_VERSION']||Calabash::Cucumber::FRAMEWORK_VERSION}.zip"
      puts "Did not find calabash.framework. I'll download it...'"
      puts "http://cloud.github.com/downloads/calabash/calabash-ios/#{zip_file}"
      require 'uri'

      uri = URI.parse "http://cloud.github.com/downloads/calabash/calabash-ios/#{zip_file}"
      success = false
      Net::HTTP.start(uri.host, uri.port) do |http|
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
      if success
        puts "\nDownload done: #{file}. Unzipping..."
        if not system("unzip -C -K -o -q -d #{project_path} #{zip_file}")
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
  pbx = PBXProject::PBXProject.new(:file => proj_file)
  pbx.parse

  pwd = FileUtils.pwd
  FileUtils.cd project_path
  ##Backup
  msg("Info") do
    puts "Making backup of project file: #{proj_file}"
    if File.exists? "#{proj_file}.bak"
      msg("Error") do
        puts "Backup file already exists. #{proj_file}.bak"
        puts "For safety, I won't overwrite this file."
        puts "You must manually move this file, if you want to"
        puts "Run calabash-ios setup again."
      end
      exit 1
    end
    FileUtils.cp(proj_file, "#{proj_file}.bak")
  end
  file = download_calabash(project_path)


  file_ref = pbx.sections['PBXFileReference'].find do |fr|
    /calabash\.framework/.match(fr.path)
  end

  if file_ref
    msg("Error") do
      puts "Your project already contains a file reference to calabash.framework."
      puts "I was not expecting this. Aborting."
    end
    exit 1
  end

  msg("Info") do
    puts "Setting up project file for calabash-ios."
  end


  ## Augment
  f = PBXProject::PBXTypes::PBXFileReference.new(:path => file, :lastKnownFileType => "wrapper.framework", :sourceTree => '"<group>"')
  f.comment = "calabash.framework"
  pbx.add_item f
  bf = PBXProject::PBXTypes::PBXBuildFile.new(:comment => "calabash.framework in Frameworks", :fileRef => f.guid)
  bf.comment = "calabash.framework in Frameworks"
  pbx.add_item bf

  group = pbx.find_item :name => "Frameworks", :type => PBXProject::PBXTypes::PBXGroup
  group.add_children f

  build_phase_entry = PBXProject::PBXTypes::BasicValue.new(:value => bf.guid, :comment => bf.comment)
  pbx.sections['PBXFrameworksBuildPhase'][0].files << build_phase_entry



  cfnet = pbx.find_item :name => "CFNetwork.framework", :type => PBXProject::PBXTypes::PBXFileReference

  unless cfnet
    f = PBXProject::PBXTypes::PBXFileReference.new(:path => "System/Library/Frameworks/CFNetwork.framework", :lastKnownFileType => "wrapper.framework", :sourceTree => 'SDKROOT')
    f.comment = "CFNetwork.framework"
    f.name = f.comment
    pbx.add_item f
    bf = PBXProject::PBXTypes::PBXBuildFile.new(:comment => "CFNetwork.framework in Frameworks", :fileRef => f.guid)
    bf.comment = "CFNetwork.framework in Frameworks"
    pbx.add_item bf
    group.add_children f
    build_phase_entry = PBXProject::PBXTypes::BasicValue.new(:value => bf.guid, :comment => bf.comment)
    pbx.sections['PBXFrameworksBuildPhase'][0].files << build_phase_entry
  end


  targets = pbx.sections['PBXNativeTarget']
  target = nil
  if targets.count == 0
    msg("Error") do
      puts "Unable to find targets in project."
      puts "Aborting..."
    end
    exit 1
  elsif (targets.count == 1)
    target = targets[0]
  else
    preferred_target = targets.find { |t| t.name.value == project_name }
    msg("Question") do
      puts "You have several targets..."
      target_names = targets.map do |t|
        n = t.name.value
        if n.length>2 and n.end_with?'"' and n.start_with?'"'
          n = n[1..n.length-2]
        end
        n
      end

      puts target_names.join("\n")

      found = nil
      until found do
        puts "Please specify which is your production app target."
        puts "Please enter target name."
        puts "Hit Enter for default choice: #{preferred_target.name.value}" unless preferred_target.nil?
        answer = STDIN.gets.chomp
        if (preferred_target and answer == '')
          target = preferred_target
          found = true
        else
          target = found = targets.find { |t| t.name.value == answer || t.name.value=="\"#{answer}\""}
        end
      end
    end
  end

  ##project level build conf
  project_bc_id = pbx.sections['PBXProject'][0].buildConfigurationList.value
  project_bc_list = pbx.find_item :guid => project_bc_id, :type => PBXProject::PBXTypes::XCConfigurationList
  project_bc_ref = project_bc_list.buildConfigurations.find { |bc| bc.comment =="Debug" }
  project_bc_id = project_bc_ref.value
  project_bc = pbx.find_item :guid => project_bc_id, :type => PBXProject::PBXTypes::XCBuildConfiguration
  project_cal_build_settings = project_bc.buildSettings.clone
  project_bc.buildSettings.each do |k, v|
    project_cal_build_settings[k] = v.clone
  end

  project_cal_bc = PBXProject::PBXTypes::XCBuildConfiguration.new(:name => "Calabash")
  project_cal_bc.buildSettings = project_cal_build_settings
  project_cal_bc.comment = "Calabash"

  ##target level build conf
  bc_list_id = target.buildConfigurationList.value
  bc_list = pbx.find_item :guid => bc_list_id, :type => PBXProject::PBXTypes::XCConfigurationList
  bc_ref = bc_list.buildConfigurations.find { |bc| bc.comment =="Debug" }
  bc_id = bc_ref.value
  bc = pbx.find_item :guid => bc_id, :type => PBXProject::PBXTypes::XCBuildConfiguration
  cal_build_settings = bc.buildSettings.clone

  bc.buildSettings.each do |k, v|
    cal_build_settings[k] = v.clone
  end

  ld_flags = cal_build_settings['OTHER_LDFLAGS'] || []
  if not ld_flags.is_a?Array
    ld_flags = [ld_flags]
  end
  danger = ld_flags.find_all {|f| /-ObjC/i.match(f.value) || /-all_load/i.match(f.value)}

  unless danger.empty?
    msg("Error") do
      puts "Detected Other Linker Flag: #{(danger.map {|d| d.value}).join(", ")}"
      puts "calabash-ios setup does not yet support this scenario"
      puts "(why? karl@lesspainful.com)"
      puts "You must manually setup ios see:"
      puts "https://github.com/calabash/calabash-ios"
    end
    exit 1
  end

  ld_flags << PBXProject::PBXTypes::BasicValue.new(:value => '"-force_load"')
  ld_flags << PBXProject::PBXTypes::BasicValue.new(:value => '"$(SRCROOT)/calabash.framework/calabash"')
  ld_flags << PBXProject::PBXTypes::BasicValue.new(:value => '"-lstdc++"')


  cal_build_settings['OTHER_LDFLAGS'] = ld_flags

  cal_bc = PBXProject::PBXTypes::XCBuildConfiguration.new(:name => "Calabash")
  cal_bc.buildSettings = cal_build_settings
  cal_bc.comment = "Calabash"

  targets.each do |target|
    bc_list_id = target.buildConfigurationList.value
    bc_list = pbx.find_item :guid => bc_list_id, :type => PBXProject::PBXTypes::XCConfigurationList
    bc_list.buildConfigurations << PBXProject::PBXTypes::BasicValue.new(:value => cal_bc.guid, :comment => "Calabash")
  end

  project_bc_list.buildConfigurations << PBXProject::PBXTypes::BasicValue.new(:value => project_cal_bc.guid, :comment => "Calabash")

  pbx.sections['XCBuildConfiguration']<<project_cal_bc
  pbx.sections['XCBuildConfiguration']<<cal_bc

  pbx.sections['XCBuildConfiguration'].each do |bc|
    sp = bc.buildSettings["FRAMEWORK_SEARCH_PATHS"] || []
    if not sp.is_a?Array
      sp = [sp]
    end
    inherit = sp.find { |x| x.value == '"$(inherited)"' }
    srcroot = sp.find { |x| x.value == "\"$(SRCROOT)\""}
    sp << PBXProject::PBXTypes::BasicValue.new(:value => '"$(inherited)"') unless inherit
    sp << PBXProject::PBXTypes::BasicValue.new(:value => "\"$(SRCROOT)\"") unless srcroot
    bc.buildSettings["FRAMEWORK_SEARCH_PATHS"] = sp
  end
  FileUtils.cd pwd
  pbx.write_to :file => proj_file
  return target
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
        msg << "You should build the -cal scheme and your normal scheme"
        msg << "(with configuration Debug)."
        msg << "Searched dir: #{dd_dir}/Build/Products"
        msg("Error") do
          puts msg.join("\n")
        end
        exit 1
      elsif sim_dirs.count != 2
        msg = ["Have you built your app for simulator?"]
        msg << "You should build the -cal scheme and your normal scheme"
        msg << "(with configuration Debug)."
        msg << "Searched dir: #{dd_dir}/Build/Products"
        msg("Error") do
          puts msg.join("\n")
        end
        exit 1
      end
      out_debug = `otool #{sim_dirs[0]}/* -o 2> /dev/null | grep CalabashServer`
      out_cal = `otool #{sim_dirs[1]}/* -o 2> /dev/null | grep CalabashServer 2> /dev/null`
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
    res = `otool #{dir}/Payload/#{app_dir}/#{app} -o 2> /dev/null | grep CalabashServer`
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
  if not Dir.exists?app
    msg("Error") do
      puts "Path: #{app} is not a directory."
    end
    exit 1
  end
  out = `otool #{app}/* -o 2> /dev/null | grep CalabashServer`

  msg("Info") do
    if /CalabashServer/.match(out)
      puts "App: #{app} *contains* calabash.framework"
    else
      puts "App: #{app} *does not contain* calabash.framework"
    end
  end

end