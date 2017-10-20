#!/usr/bin/env bash

script/ci/jenkins/rspec.sh
script/ci/cli.sh

(cd calabash-cucumber/test/cucumber; ./run.sh)

