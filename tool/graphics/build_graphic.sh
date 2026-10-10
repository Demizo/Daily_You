#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

if command -v inkscape >/dev/null && command -v gifsicle >/dev/null && python3 -c 'import PIL' 2>/dev/null; then
  exec python3 "$here/build_graphic.py" "$@"
fi
exec nix shell --impure --expr '
  let pkgs = import <nixpkgs> { };
  in pkgs.buildEnv {
    name = "graphics-tools";
    paths = [ pkgs.inkscape pkgs.gifsicle (pkgs.python3.withPackages (packages: [ packages.pillow ])) ];
  }' \
  --command python3 "$here/build_graphic.py" "$@"
