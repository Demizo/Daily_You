# Animated graphics

Each folder is a graphic: layered SVGs plus a `graphic.json` to define the order and animations.

```sh
tool/graphics/build_graphic.sh app_banner
```

To add a graphic, create a folder with its SVGs and a `graphic.json`.

Needs inkscape, gifsicle and python3 with Pillow; `nix shell` fetches them if missing.
