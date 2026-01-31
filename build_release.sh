#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(pwd)"
OUTPUT_DIR="build/app/outputs/flutter-apk"
DEST_DIR="/home/demizo/Downloads/Daily You Releases"

echo "=== Build Daily You Release ==="
echo

read -rp "Version name (e.g. 1.23.4): " VERSION_NAME

echo
echo "Running Flutter builds..."

flutter build apk \
  --flavor independent \
  --release \
  --split-per-abi \
  --target-platform=android-arm64

flutter build apk \
  --flavor independent \
  --release \
  --split-per-abi \
  --target-platform=android-arm

flutter build apk \
  --flavor independent \
  --release \
  --split-per-abi \
  --target-platform=android-x64

echo
echo "Copying APKs..."

mkdir -p "$DEST_DIR"

cp "${OUTPUT_DIR}/app-arm64-v8a-independent-release.apk" \
   "${DEST_DIR}/daily-you-arm64-v8a-v${VERSION_NAME}.apk"

cp "${OUTPUT_DIR}/app-armeabi-v7a-independent-release.apk" \
   "${DEST_DIR}/daily-you-armeabi-v7a-v${VERSION_NAME}.apk"

cp "${OUTPUT_DIR}/app-x86_64-independent-release.apk" \
   "${DEST_DIR}/daily-you-x86_64-v${VERSION_NAME}.apk"

echo
echo "Build complete"
echo "APKs available in:"
echo "  $DEST_DIR"

