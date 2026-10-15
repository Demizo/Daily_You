#!/usr/bin/env python3
import json
import math
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ElementTree
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageChops

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SETTINGS = {"frames": 48, "duration": 100, "width": 1024, "colors": 48}
SVG_NAMESPACE = "http://www.w3.org/2000/svg"


def parse_length(text):
    return float(re.match(r"[-+0-9.eE]+", text).group(0))


class Layer:
    def __init__(self, path):
        self.path = path
        self.root = ElementTree.parse(path).getroot()
        view_box = [float(value) for value in self.root.get("viewBox").split()]
        self.size = (view_box[2], view_box[3])
        # inkscape reports bounding boxes in document pixels, not viewBox units
        self.unit_scale = (
            view_box[2] / parse_length(self.root.get("width", str(view_box[2]))),
            view_box[3] / parse_length(self.root.get("height", str(view_box[3]))),
        )
        self.ids = {element.get("id") for element in self.root.iter()}

    def centers(self, targets):
        wanted = [target for target in targets if target in self.ids]
        if not wanted:
            return {}
        output = subprocess.run(
            ["inkscape", "--query-all", str(self.path)], capture_output=True, text=True, check=True
        ).stdout
        centers = {}
        for line in output.splitlines():
            element_id, left, top, width, height = line.split(",")
            if element_id in wanted:
                centers[element_id] = (
                    (float(left) + float(width) / 2) * self.unit_scale[0],
                    (float(top) + float(height) / 2) * self.unit_scale[1],
                )
        return centers


def wobble(progress, rotation=0.0, scale=0.0, phase=0.0):
    angle = 2 * math.pi * progress + phase
    return "rotate(%.4f) scale(%.5f)" % (rotation * math.sin(angle), 1 + scale * math.sin(angle + math.pi / 2)), 1.0


def bob(progress, amplitude=0.0, cycles=1):
    return "translate(0 %.3f)" % (amplitude * math.sin(2 * math.pi * progress * cycles)), 1.0


def travel(progress, dx=0.0, dy=0.0, start=0.0, duration=1.0, ease=1.0, ease_x=None, turn=0.0, end_scale=1.0, fade_in=0.15, fade_out=0.15):
    elapsed = (progress - start) % 1 / duration
    if elapsed >= 1:
        return "", 0.0
    position = elapsed**ease
    position_x = elapsed ** (ease if ease_x is None else ease_x)
    transform = "translate(%.3f %.3f) rotate(%.3f) scale(%.4f)" % (
        dx * position_x,
        dy * position,
        turn * position,
        1 + (end_scale - 1) * position,
    )
    return transform, min(1.0, elapsed / fade_in, (1 - elapsed) / fade_out)


def punch(progress, cycles=1, phase=0.0, decay=7.0, spring=9.0, dy=0.0, scale_x=0.0, scale_y=0.0):
    elapsed = (progress * cycles - phase) % 1
    amount = math.exp(-decay * elapsed) * math.cos(spring * elapsed)
    return "translate(0 %.3f) scale(%.5f %.5f)" % (dy * amount, 1 + scale_x * amount, 1 + scale_y * amount), 1.0


def show(progress, windows=((0.0, 1.0),), repeat=1):
    position = progress * repeat % 1
    return "", 1.0 if any(start <= position < end for start, end in windows) else 0.0


MOTIONS = {"wobble": wobble, "bob": bob, "travel": travel, "punch": punch, "show": show}


def load_layers(folder, layer_names, animations):
    layers = [Layer(folder / name) for name in layer_names]
    if len({layer.size for layer in layers}) != 1:
        raise SystemExit("all layers need the same viewBox size")
    for target, motions in animations.items():
        if not any(target in layer.ids for layer in layers):
            raise SystemExit("animation target %s is not in any layer" % target)
        for motion in motions:
            if motion["type"] not in MOTIONS:
                raise SystemExit("%s: unknown motion %s, expected one of %s" % (target, motion["type"], sorted(MOTIONS)))
    return layers


def frame_svg(progress, layers, animations, centers):
    width, height = layers[0].size
    root = ElementTree.Element(
        "{%s}svg" % SVG_NAMESPACE,
        {"width": "%g" % width, "height": "%g" % height, "viewBox": "0 0 %g %g" % (width, height)},
    )
    for layer in layers:
        group = ElementTree.SubElement(root, "{%s}g" % SVG_NAMESPACE)
        group.extend(ElementTree.parse(layer.path).getroot())
        parents = {child: parent for parent in group.iter() for child in parent}
        for element in list(group.iter()):
            if element.get("id") not in animations or element not in parents:
                continue
            center_x, center_y = centers[element.get("id")]
            results = [
                MOTIONS[motion["type"]](progress, **{key: value for key, value in motion.items() if key != "type"})
                for motion in animations[element.get("id")]
            ]
            motions = " ".join(transform for transform, _ in results if transform)
            opacity = math.prod(opacity for _, opacity in results)
            parent = parents[element]
            attributes = {"transform": "translate(%.3f %.3f) %s translate(%.3f %.3f)" % (center_x, center_y, motions, -center_x, -center_y)}
            if opacity < 1:
                attributes["opacity"] = "%.3f" % opacity
            wrapper = ElementTree.Element("{%s}g" % SVG_NAMESPACE, attributes)
            parent.insert(list(parent).index(element), wrapper)
            parent.remove(element)
            wrapper.append(element)
    return ElementTree.tostring(root, encoding="unicode")


def rasterize(svg_path, png_path, width):
    # inkscape occasionally fails when launched in parallel
    for attempt in range(8):
        time.sleep(0.3 * attempt)
        subprocess.run(
            ["inkscape", str(svg_path), "-w", str(width), "-o", str(png_path)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if png_path.exists() and png_path.stat().st_size:
            return
    raise RuntimeError("inkscape failed on %s" % svg_path)


def binary_alpha(value):
    return 255 if value >= 128 else 0


def build_gif(png_paths, output, colors, duration):
    images = [Image.open(path).convert("RGBA") for path in png_paths]
    transparent_index = colors - 1
    samples = images[::4]
    width, height = samples[0].size
    mosaic = Image.new("RGB", (width, height * len(samples)))
    for position, image in enumerate(samples):
        backdrop = Image.new("RGB", image.size)
        backdrop.paste(image.convert("RGB"), mask=image.getchannel("A").point(binary_alpha))
        mosaic.paste(backdrop, (0, position * height))
    quantized = mosaic.quantize(colors=transparent_index, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    palette = quantized.getpalette()[: transparent_index * 3]
    palette_image = Image.new("P", (1, 1))
    palette_image.putpalette(palette + [0] * (768 - len(palette)))
    frames = []
    for image in images:
        frame = image.convert("RGB").quantize(palette=palette_image, dither=Image.Dither.NONE)
        frame.paste(transparent_index, mask=ImageChops.invert(image.getchannel("A").point(binary_alpha)))
        frames.append(frame)
    unoptimized = output.with_suffix(".raw.gif")
    frames[0].save(
        unoptimized,
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        transparency=transparent_index,
        disposal=2,
        optimize=False,
    )
    subprocess.run(["gifsicle", "-O3", str(unoptimized), "-o", str(output)], check=True)
    unoptimized.unlink()


def main():
    folder = Path(__file__).resolve().parent / sys.argv[1]
    manifest = {**DEFAULT_SETTINGS, **json.loads((folder / "graphic.json").read_text())}
    output = REPOSITORY_ROOT / manifest["output"]
    animations = manifest.get("animations", {})
    layers = load_layers(folder, manifest["layers"], animations)
    centers = {}
    for layer in layers:
        centers.update(layer.centers(animations))
    with tempfile.TemporaryDirectory() as temporary:
        svg_paths = []
        for frame in range(manifest["frames"]):
            path = Path(temporary) / ("%03d.svg" % frame)
            path.write_text(frame_svg(frame / manifest["frames"], layers, animations, centers))
            svg_paths.append(path)
        png_paths = [path.with_suffix(".png") for path in svg_paths]
        with ThreadPoolExecutor(4) as executor:
            list(executor.map(lambda paths: rasterize(*paths, manifest["width"]), zip(svg_paths, png_paths)))
        build_gif(png_paths, output, manifest["colors"], manifest["duration"])
    print("%s: %.0f KB" % (output, output.stat().st_size / 1024))


if __name__ == "__main__":
    main()
