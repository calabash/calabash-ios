
def calabash_scaffold
  if File.exists?(@features_dir)
    puts "A features directory already exists. Stopping..."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a features directory here:"
    puts ""
    puts "#{ENV['PWD']}/features"
    puts ""
    puts "This directory will contain all of your calabash tests."
    puts "Shall I proceed? (Y/n)"
  end

  response = STDIN.gets.chomp.downcase
  proceed = response == "" || response == "y"

  exit 2 unless proceed
  FileUtils.cp_r(@source_dir, @features_dir)
end
