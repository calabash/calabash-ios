#!/usr/bin/env bash

cd calabash-cucumber
rbenv local 2.2.3
gem uninstall -Vax --force --no-abort-on-dependent run_loop
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

