#!/usr/bin/env bash

cd calabash-cucumber

function info {
  echo "$(tput setaf 2)INFO: $1$(tput sgr0)"
}

set -e

export DEBUG=1

info "Testing 'calabash-ios'"
bundle exec calabash-ios

info "Testing 'calabash-ios help'"
bundle exec calabash-ios help

info "Testing 'calabash-ios version'"
bundle exec calabash-ios version

info "Testing 'calabash-ios check .app'"
bundle exec calabash-ios check spec/resources/CalSmoke-cal.app

info "Testing 'calabash-ios check .ipa'"
bundle exec calabash-ios check spec/resources/LPSimpleExample-cal.ipa

info "Testing 'calabash-ios check .app' without calabash"
set +e
bundle exec calabash-ios check spec/resources/CalSmoke.app
if [ "$?" != "1" ]; then
  exit 1
fi
set -e

info "Testing 'calabash-ios sim locale' usage info"
bundle exec calabash-ios sim locale

info "Testing 'calabash-ios sim reset'"
bundle exec calabash-ios sim reset

info "Testing 'calabash-ios sim acc'"
bundle exec calabash-ios sim acc

