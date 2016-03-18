#!/usr/bin/env bash

cd calabash-cucumber
bundle update
rm -rf spec/reports

rbenv exec \
  bundle exec \
  rspec \
  spec/lib

rbenv exec \
  bundle exec \
  rspec \
  spec/bin/calabash_ios_sim_spec.rb

rbenv exec \
  bundle exec \
  rspec \
  spec/integration/device_spec.rb

