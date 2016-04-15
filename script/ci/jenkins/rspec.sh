#!/usr/bin/env bash

cd calabash-cucumber
bundle update
rm -rf spec/reports

rbenv exec \
  bundle exec \
  rspec \
  spec/lib \
  spec/bin \
  spec/integration \

