#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="https://api.pgoapp.com/api"
SHARE_BASE_URL="https://pgoapp.com"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "FAIL: iOS release validation requires macOS with Xcode."
  exit 1
fi

flutter clean
flutter pub get

cd ios
pod install --repo-update
cd ..

flutter build ios --release --no-codesign \
  --dart-define="API_BASE_URL=${API_BASE_URL}" \
  --dart-define="SHARE_BASE_URL=${SHARE_BASE_URL}"

