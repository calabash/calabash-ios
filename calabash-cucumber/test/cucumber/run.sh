#!/usr/bin/env bash

bundle update

# Assumes Xcode 7.3.1 on Jenkins.
bundle exec cucumber -f pretty -f json -o reports/instruments.json
