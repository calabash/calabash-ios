#!/usr/bin/env bash

set -e

source bin/ci/log_functions.sh

banner "Setup Gem Environment"

GEMRC="${HOME}/.gemrc"
echo "install: --no-document --env-shebang" > "${GEMRC}"
echo "update: --no-document --env-shebang" >> "${GEMRC}"

cat "${GEMRC}"

gem install luffa
gem install xcpretty
gem install dotenv
gem install xamarin-test-cloud

banner "Authorize UIAutomation"
luffa authorize

banner "Install run_loop Develop Branch"
rm -rf run_loop
git clone --branch develop --depth 1 --recursive https://github.com/calabash/run_loop
(cd run_loop && bundle update)
(cd run_loop && rake install)

banner "Install Stubs for LPServer libs"

mkdir -p calabash-cucumber/staticlib
touch calabash-cucumber/staticlib/calabash.framework.zip
touch calabash-cucumber/staticlib/libFrankCalabash.a
mkdir -p calabash-cucumber/dylibs
touch calabash-cucumber/dylibs/libCalabashDyn.dylib
touch calabash-cucumber/dylibs/libCalabashDynSim.dylib

banner "Install Gem"

(cd calabash-cucumber && bundle install)
(cd calabash-cucumber && rake install)

banner "rspec"

cd calabash-cucumber
rm -rf spec/reports

bundle exec \
  rspec \
  spec/lib \
  spec/integration/launcher/console_attach_spec.rb

banner "CLI"

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

info "Testing 'calabash-ios sim locale' usage info"
bundle exec calabash-ios sim locale

info "Testing 'calabash-ios sim reset'"
bundle exec calabash-ios sim reset

info "Testing 'calabash-ios sim acc'"
bundle exec calabash-ios sim acc

