#!/usr/bin/env bash

bundle update

bundle exec cucumber -f pretty -f json -o reports/instruments.json

CBX_LAUNCHER=ios_device_manager bundle exec \
  cucumber -f pretty -f json -o reports/device-agent.json
