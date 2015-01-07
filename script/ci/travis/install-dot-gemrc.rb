#!/usr/bin/env ruby

gemrc_file = File.expand_path('~/.gemrc')
File.open(gemrc_file, 'w') do |file|
  file.write("install: --no-document --env-shebang\n")
  file.write("update:  --no-document --env-shebang")
end

