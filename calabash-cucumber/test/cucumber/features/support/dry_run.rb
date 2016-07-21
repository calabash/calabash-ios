require "calabash-cucumber"

# Cucumber -d must pass, but support/env.rb is not eval'd on dry runs.
# We must detect that the user wants to use pre-defined steps.
dir = File.expand_path(File.dirname(__FILE__))
env = File.join(dir, "env.rb")

contents = File.read(env).force_encoding("UTF-8")

contents.split($-0).each do |line|

  # Skip comments.
  next if line.chars[0] == "#"

  if line[/calabash-cucumber\/cucumber/, 0]
    require "calabash-cucumber/calabash_steps"
    break
  end
end
