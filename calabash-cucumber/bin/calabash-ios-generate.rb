
def calabash_scaffold
  if File.exists?(@features_dir)
    puts "A features directory already exists. Stopping..."
    #puts "Run calabash-ios update for update instructions."
    exit 1
  end
  msg("Question") do
    puts "I'm about to create a subdirectory called features."
    puts "features will contain all your calabash tests."
    puts "Please hit return to confirm that's what you want."
  end
  exit 2 unless STDIN.gets.chomp == ''

  FileUtils.cp_r(@source_dir, @features_dir)
  FileUtils.mv "#{@features_dir}/.irbrc", "."
  FileUtils.mv "#{@features_dir}/irb_ios4.sh", "."
  FileUtils.mv "#{@features_dir}/irb_ios5.sh", "."

  msg("Info") do
    puts "Features subdirectory created. \n"
    puts "Make sure you've build your -cal scheme in XCode and "
    puts "try executing \n\ncucumber"
  end

end
