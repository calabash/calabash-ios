#!/usr/bin/env bash

function banner {
  if [ "${TERM}" = "dumb" ]; then
    echo ""
    echo "######## $1 ########"
    echo ""
  else
    echo ""
    echo "$(tput setaf 5)######## $1 ########$(tput sgr0)"
    echo ""
  fi
}

for i in {1..20}; do
  banner "Try number $i of 20"
  #DEVELOPER_DIR=/Xcode/8.0b3/Xcode-beta.app/Contents/Developer \
  CODE_SIGN_IDENTITY="iPhone Developer: Karl Krukow (YTTN6Y2QS9)" \
    CBX_LAUNCHER=xcodebuild \
    bundle exec cucumber -t @touch -p pegasi
  sleep 5
done

