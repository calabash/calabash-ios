
def build(options={:build_dir=>"Calabash",
                   :configuration => "Debug",
                   :sdk => "iphonesimulator",
                   :dstroot => "Calabash/build",
                   :wrapper_name => "Calabash.app"})
  #Follow Pete's .xcconfig-based approach with zero-config

  if !File.exists?("#{options[:build_dir]}/cal.xcconfig")
      FileUtils.cp(File.join(File.dirname(__FILE__),"cal.xcconfig"),"#{options[:build_dir]}/cal.xcconfig")
  end

  cmd=["xcodebuild"]
  cmd << %Q[-xcconfig "#{options[:build_dir]}/cal.xcconfig"]
  cmd << "install"

  (options[:target] || []).each do |tgt|
    options << %Q[-target "#{tgt}"]
  end

  cmd << "-configuration"
  cmd << %Q["#{options[:configuration]}"]

  cmd << "-sdk"
  cmd << %Q["#{options[:sdk]}"]

  cmd << %Q[DSTROOT="#{options[:dstroot]}"]

  cmd << %Q[WRAPPER_NAME="#{options[:wrapper_name]}"]

  msg("Calabash Build") do
    cmd_s = cmd.join(" ")
    puts cmd_s
    system(cmd_s)
  end
end

def console(options={:script => "irb_ios5.sh"})
  if !File.exists?(".irbrc")
    puts "Copying calabash-ios .irbrc file to current directory..."
    FileUtils.cp(File.join(@source_dir,".irbrc"), ".")
  end
  if !File.exists?(options[:script])
    puts "Copying calabash-ios #{options[:script]} file to current directory..."
    FileUtils.cp(File.join(@source_dir,options[:script]), ".")
  end
  puts "Running irb with ./.irbrc..."
  system("./#{options[:script]}")
end
