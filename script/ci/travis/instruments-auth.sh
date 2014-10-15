#!/usr/bin/env bash
SCRIPT_DIR="${PWD}/script/ci/travis"
sudo security authorizationdb write com.apple.dt.instruments.process.analysis <  $SCRIPT_DIR/com.apple.dt.instruments.process.analysis.plist
sudo security authorizationdb write com.apple.dt.instruments.process.kill <  $SCRIPT_DIR/com.apple.dt.instruments.process.kill.plist
