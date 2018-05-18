#!/usr/bin/env bash

bundle update

bundle exec cucumber -t ~@flick -f pretty -f json -o reports/instruments.json -f junit -o reports/junit
