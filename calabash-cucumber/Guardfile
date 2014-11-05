notification :growl, sticky: false, priority: 0
logger level: :info

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

# NOTE: This Guardfile only watches unit specs.
# Automatically running the integration specs would repeatedly launch the
# simulator, stealing screen focus and making everyone cranky.
guard :rspec, cmd: 'bundle exec rspec', spec_paths: ['spec/lib'] do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/calabash-cucumber/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec/lib' }
end

