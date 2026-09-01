#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Flutter dependencies"
flutter pub get

echo "==> Running static analysis"
flutter analyze

echo "==> Running test suite"
flutter test

if [[ "${VERIFY_BUILD:-0}" == "1" ]]; then
  echo "==> Building production web bundle"
  flutter build web --release --base-href "/warmmemo/"
fi

echo "Verification complete. Record the command and result in progress.md."
