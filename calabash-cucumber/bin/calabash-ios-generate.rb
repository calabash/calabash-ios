
def calabash_scaffold
  if File.exists?(@features_dir)
    puts "A features directory already exists. Stopping..."
    exit 1
  end

  msg("Question") do
    puts "I'm about to create a features directory here:"
    puts ""
    puts "#{ENV["PWD"]}/features"
    puts ""
    puts "This directory will contain all of your calabash tests."
    puts "Shall I proceed? (Y/n)"
  end

  response = STDIN.gets.chomp.downcase
  proceed = response == "" || response == "y"

  puts ""

  if !proceed
    puts "Skipping installation of features/ directory"
  else
    FileUtils.cp_r(@source_dir, @features_dir)
    puts "Created: #{ENV["PWD"]}/features"
    puts ""
  end

  gemfile = File.join(ENV["PWD"], "Gemfile")

  version = Calabash::Cucumber::VERSION
  gemline = "gem \"calabash-cucumber\", \">= #{version}\", \"< 2.0\"\n"

  if File.exist?(gemfile)
    printf "Found a Gemfile..."
    contents = File.read(gemfile).force_encoding('utf-8')
    if contents[/calabash-cucumber/, 0]
      puts "and it contains calabash-cucumber!"
      puts ""
    else
      puts "but it doesn't contain calabash-cucumber!"
      puts "You'll have to add it yourself"
      puts ""
      puts "> #{gemline}"
      puts ""
    end
  else
    msg("Question") do
      puts "I want to create a Gemfile for you."
      puts "Shall I proceed? (Y/n)"

      response = STDIN.gets.chomp.downcase
      proceed = response == "" || response == "y"

      puts ""

      if !proceed
        puts "Skipping installation of Gemfile"
      else
        File.open(gemfile, "w") do |file|
          file.write("source \"https://rubygems.org\"\n")
          file.write("\n")
          file.write(gemline)
          file.write("\n")
        end
        puts "Created: #{gemfile}"
        puts""
      end
    end
  end
  puts "My work is done here."
end

