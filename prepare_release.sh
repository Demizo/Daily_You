#!/usr/bin/env bash
set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <changelog-file>"
  exit 1
fi

CHANGELOG_FILE="$1"

if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "Error: changelog file not found: $CHANGELOG_FILE"
  exit 1
fi

PROJECT_ROOT="$(pwd)"
FASTLANE_CHANGELOG_DIR="fastlane/metadata/android/en-US/changelogs"

echo "=== Prepare Daily You Release ==="
echo

read -rp "Version name (e.g. 1.23.4): " VERSION_NAME
read -rp "Version code (e.g. 1023004): " VERSION_CODE

echo
echo "Using changelog file: $CHANGELOG_FILE"
echo "--------------------------------"
cat "$CHANGELOG_FILE"
echo "--------------------------------"
echo

read -rp "Continue? [y/N]: " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 1

echo
echo "Updating pubspec.yaml..."
sed -i \
  -E "s/^version: .*/version: ${VERSION_NAME}+${VERSION_CODE}/" \
  pubspec.yaml

echo "Updating AppImageBuilder.yml..."
sed -i -E \
  's/^([[:space:]]{4}version:).*/\1 '"${VERSION_NAME}"'/' \
  AppImageBuilder.yml

echo "Creating Fastlane changelog files..."
mkdir -p "$FASTLANE_CHANGELOG_DIR"

for i in 1 2 3; do
  FILE="${FASTLANE_CHANGELOG_DIR}/${VERSION_CODE}${i}.txt"
  cp "$CHANGELOG_FILE" "$FILE"
  echo "  - $FILE"
done

echo
echo "Release preparation complete"
echo "  Version name: $VERSION_NAME"
echo "  Version code: $VERSION_CODE"

