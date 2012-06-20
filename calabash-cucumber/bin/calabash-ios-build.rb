
def build(options={:build_dir=>"Calabash"})
  raise "not supported yet... coming soon"
  #Follow Pete's .xcconfig-based approach with zero-config
  #`xcodebuild -xcconfig Calabash/cal.xcconfig install -configuration Debug -sdk iphonesimulator DSTROOT=Calabash/build WRAPPER_NAME=Calabash.app`
end

def console(options={:script => "irb_ios5.sh"})
  if !File.exists?(".irbrc")
    FileUtils.cp(File.join(@source_dir,".irbrc"), ".")
  end
  if !File.exists?(options[:script])
    FileUtils.cp(File.join(@source_dir,options[:script]), ".")
  end
  system("./#{options[:script]}")
end
