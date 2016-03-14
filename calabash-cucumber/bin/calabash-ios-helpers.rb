require 'tempfile'
require 'json'

UPDATE_TARGETS = ['hooks']

def msg(title, &block)
  puts "\n" + "-"*10 + title + "-"*10
  block.call
  puts "-"*10 + "-------" + "-"*10 + "\n"
end


def print_usage
  puts <<EOF
  Usage: calabash-ios <command> [<args>]
  where <command> can be one of
    help
      prints more detailed help information.
    gen
      generate a features folder structure.
    console
      starts an interactive console to interact with your app via Calabash
    setup [<path>]
      setup your XCode project for calabash-ios (EXPERIMENTAL)
    download
      install latest compatible version of calabash.framework
    check [{<path to .ipa>|<path to .app>}]
      check whether an app or ipa is linked with calabash.framework (EXPERIMENTAL)
    sim locale <lang> [<region>]
      change locale and regional settings in all iOS Simulators
    sim location {on|off} <bundleid>
      set allow location on/off for current project or bundleid
    sim reset
      reset content and settings in all iOS Simulators
    sim acc
      enable accessibility in all iOS Simulators
EOF
end

def print_help
  file = File.join(File.dirname(__FILE__), '..', 'doc', 'calabash-ios-help.txt')
  system("less #{file}")
end

def ensure_correct_path(args)
  dir_to_search = nil
  if args.length == 1
    dir_to_search = args[0]
    if not File.directory?(dir_to_search)
      puts "Path: #{dir_to_search} is not a directory."
      puts "It should be your project directory (i.e., the one containing your <projectname.xcodeproject>)."
      exit 1
    end
  else
    dir_to_search = "."
  end

  project_files = Dir.foreach(dir_to_search).find_all { |x| /\.xcodeproj$/.match(x) }
  if project_files.empty?
    puts "Found no *.xcodeproj files in dir #{dir_to_search}."
    exit 1
  end
  if project_files.count > 1
    puts "Found several *.xcodeproj files in dir #{dir_to_search}."
    puts "Found: #{project_files.join("\n")}"
    puts "We don't yet support this. Please setup calabash manually."
    exit 1
  end
  return dir_to_search,project_files
end
