#!/usr/bin/env bash

bundle update

bundle exec cucumber -t ~@flick -f pretty -f junit -o reports/junit
