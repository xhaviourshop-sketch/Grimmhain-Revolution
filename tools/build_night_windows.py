"""Finds the lit windows of the night scene and builds the runtime images for the window-glow shader (P4 atmosphere).

Repeatable: run from the repository root
    python tools/build_night_windows.py [--source <png>] [--control <png>]
Reads the AI-generated night scene (1536x1024) and writes
    godot/assets/night/bg/scene-night-base.webp     scene with the window islands darkened (additive light cannot darken)
    godot/assets/night/bg/scene-night-windows.png   ID map, 8 bit gray: 0 = no window, 1..N = island id (lossless, no filtering)
    <control>                                       control image with numbered islands (not part of the repository)
Islands are connected components of warm bright pixels; specks, oversize blobs and anything on the plaza (cobble glints) is dropped.
Run `godot --path godot --import` afterwards so the new files get their .import sidecars.
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = ROOT + "/godot/assets/night/bg/"
DEFAULT_SOURCE = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/szene-nacht-v1.png"
DEFAULT_CONTROL = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/p4-atmosphaere/kontrolle-fenster.png"

RED_MIN = 170          # warm bright pixels: red channel at least this
WARM_MIN = 50          # and red minus blue at least this
GREEN_MIN = 90
CLOSE_ITERATIONS = 2   # bridges the window bars, so one window stays one island
MIN_AREA = 30          # px, smaller blobs are sparks or reflections
MAX_AREA = 2500        # px, larger blobs are no windows
GROW = 2               # px, island margin so the glow covers the window frame edge
PLAZA_CENTER = (768.0, 585.0)
PLAZA_RADII = (600.0, 305.0)  # (rx, ry) of the cobbled plaza; islands whose center lies inside are glints, not windows
DIM = 0.3              # base image brightness inside islands; the shader adds it back (1 / DIM - 1) * flicker


def find_islands(rgb):
    r, g, b = (rgb[..., i].astype(int) for i in range(3))
    mask = (r > RED_MIN) & (r - b > WARM_MIN) & (g > GREEN_MIN)
    mask = ndi.binary_closing(mask, structure=np.ones((3, 3)), iterations=CLOSE_ITERATIONS)
    labels, count = ndi.label(mask)
    kept = []
    for index in range(1, count + 1):
        ys, xs = np.nonzero(labels == index)
        area = len(xs)
        cx, cy = float(xs.mean()), float(ys.mean())
        inside = ((cx - PLAZA_CENTER[0]) / PLAZA_RADII[0]) ** 2 + ((cy - PLAZA_CENTER[1]) / PLAZA_RADII[1]) ** 2 < 1.0
        if MIN_AREA <= area <= MAX_AREA and not inside:
            kept.append((index, cx, cy, area))
    return labels, kept


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=DEFAULT_SOURCE)
    parser.add_argument("--control", default=DEFAULT_CONTROL)
    args = parser.parse_args()

    image = Image.open(args.source).convert("RGB")
    rgb = np.asarray(image)
    labels, kept = find_islands(rgb)
    if len(kept) > 255:
        raise SystemExit("more than 255 islands, the 8 bit ID map cannot hold them")

    id_map = np.zeros(labels.shape, np.uint8)
    for new_id, (index, _cx, _cy, _area) in enumerate(kept, start=1):
        id_map[labels == index] = new_id
    if GROW > 0:  # grow each island by its nearest neighbour label so ids stay distinct
        distance, (iy, ix) = ndi.distance_transform_edt(id_map == 0, return_indices=True)
        grown = id_map[iy, ix]
        id_map = np.where((id_map == 0) & (distance <= GROW), grown, id_map).astype(np.uint8)

    base = rgb.astype(np.float32)
    inside = id_map > 0
    base[inside] *= DIM
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(base + 0.5, 0, 255).astype(np.uint8)).save(OUT + "scene-night-base.webp", lossless=True, quality=100, method=6)
    Image.fromarray(id_map).save(OUT + "scene-night-windows.png", optimize=True)

    control = image.copy()
    draw = ImageDraw.Draw(control)
    for new_id, (_index, cx, cy, _area) in enumerate(kept, start=1):
        ys, xs = np.nonzero(id_map == new_id)
        draw.rectangle([xs.min() - 2, ys.min() - 2, xs.max() + 2, ys.max() + 2], outline=(0, 255, 90))
        draw.text((xs.max() + 4, ys.min() - 4), str(new_id), fill=(255, 255, 0))
    cx0, cy0 = PLAZA_CENTER
    rx, ry = PLAZA_RADII
    draw.ellipse([cx0 - rx, cy0 - ry, cx0 + rx, cy0 + ry], outline=(255, 0, 255))
    os.makedirs(os.path.dirname(args.control), exist_ok=True)
    control.save(args.control)
    print("islands: %d" % len(kept))


if __name__ == "__main__":
    main()
