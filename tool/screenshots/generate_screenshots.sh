#!/usr/bin/env bash
set -euo pipefail

application_id="com.demizo.daily_you"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
real_data_dir="$data_home/$application_id"
backup_dir="${real_data_dir}.screenshot-backup"

repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
cd "$repo_root"

if [[ -e "$backup_dir" ]]; then
  echo "error: found a leftover backup at $backup_dir." >&2
  echo "A previous run didn't clean up. Move it back to $real_data_dir" >&2
  echo "yourself (or remove it, if it's disposable) before running this again." >&2
  exit 1
fi

echo "This will move your real Daily You data:"
echo "  $real_data_dir"
echo "to:"
echo "  $backup_dir"
echo "generate screenshots, then restore it."
read -r -p "Continue? [y/N] " reply
case "$reply" in
  [yY] | [yY][eE][sS]) ;;
  *)
    echo "Aborted."
    exit 1
    ;;
esac

moved=false
if [[ -e "$real_data_dir" ]]; then
  mv "$real_data_dir" "$backup_dir"
  moved=true
fi

restore_real_data() {
  local status=$?
  trap - EXIT INT TERM
  rm -rf "$real_data_dir"
  if [[ "$moved" == true ]]; then
    mv "$backup_dir" "$real_data_dir"
    echo "Restored your real Daily You data."
  fi
  exit "$status"
}
trap restore_real_data EXIT INT TERM

xvfb-run -a flutter test integration_test/screenshot_test.dart -d linux --update-goldens

echo
read -r -p "Promote staged screenshots into fastlane/metadata? [y/N] " promote_reply
case "$promote_reply" in
  [yY] | [yY][eE][sS])
    dart run tool/promote_screenshots.dart
    ;;
  *)
    echo "Skipped. Run 'dart run tool/promote_screenshots.dart' when ready."
    ;;
esac
