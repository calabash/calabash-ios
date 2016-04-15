#!/usr/bin/env bash

cd calabash-cucumber
bundle update
rm -rf spec/reports

bundle exec \
  rspec \
  spec/lib \
  spec/integration/launcher/console_attach_spec.rb

