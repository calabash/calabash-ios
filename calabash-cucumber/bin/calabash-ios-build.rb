
def console
  path = ENV['CALABASH_IRBRC']
  unless path
    if File.exist?('.irbrc')
      path = File.expand_path('.irbrc')
    end
  end
  unless path
    path = File.expand_path(File.join(@script_dir,".irbrc"))
  end
  ENV['IRBRC'] = path
  puts "Running irb..."
  exec("irb")
end
