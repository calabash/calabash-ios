#!/usr/bin/env bash

# Enable binaries to be installed.
#
# calabash-cucumber at /Users/travis/build/calabash/calabash-ios/calabash-cucumber did not have a valid gemspec.
# This prevents bundler from installing bins or native extensions, but that may not affect its functionality.
# The validation message from Rubygems was:
#  ["staticlib/calabash.framework.zip"] are not files
touch calabash.framework
zip -r calabash.framework.zip calabash.framework
mkdir -p staticlib
mv calabash.framework.zip staticlib/
rm calabash.framework

gem install --no-document bundler
RETVAL=$?
if [ $RETVAL != 0 ]; then
    echo "FAIL: failed to install bundler"
    exit $RETVAL
else
    echo "INFO: installed bundler"
fi

bundle install --deployment
RETVAL=$?
if [ $RETVAL != 0 ]; then
    echo "FAIL: failed to bundle install"
    exit $RETVAL
else
    echo "INFO: bundled"
fi

exit $RETVAL
