"""Cuts the three team symbols (village, wolves, solo) out of the AI-generated sheet and tones them to the moon silver of the night board.

Repeatable: run from the repository root
    python tools/build_team_symbols.py [--source <png>] [--preview <png>]
Reads team-symbole.png (three motifs side by side on a transparent ground, real alpha channel) and writes
godot/assets/night/team/team-village.png, team-wolves.png and team-solo.png (256x256, alpha kept).
The motifs are found as connected alpha regions (slightly dilated so thin gaps close), ordered left to right. Each one is cropped as a
centered square with a little margin and resized in premultiplied alpha (no color fringes). The sepia of the sheet is pulled toward the
moon silver (ThemeTokens.MOON_SILVER): luminance is kept, the hue is blended with the silver tint, so the symbols sit next to the silver
role emblems. Run `godot --path godot --import` afterwards so new files get their .import sidecars.
"""
import argparse
import os

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = ROOT + "/godot/assets/night/team/"
DEFAULT_SOURCE = "C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/symbole/team-symbole.png"
NAMES = ["team-village", "team-wolves", "team-solo"]
THRESHOLD = 24     # alpha above this counts as motif
MERGE_GAP = 25     # dilation iterations that close the gaps inside one motif (the lantern touches the house only loosely)
MARGIN = 0.04      # extra border around the motif, share of its side
SIZE = 256
SILVER = np.array([197.0, 205.0, 219.0])  # ThemeTokens.MOON_SILVER #c5cddb
TONE_STRENGTH = 0.6  # share of the silver tint blended over the sepia (0 = untouched)


def tone(rgb):
    """Keeps the luminance of every pixel and blends its hue toward the moon silver."""
    lum = rgb.mean(axis=-1, keepdims=True)
    silver = SILVER / SILVER.mean() * lum
    return np.clip(rgb * (1 - TONE_STRENGTH) + silver * TONE_STRENGTH, 0, 255)


def motifs(alpha):
    """Boolean masks of the three motifs, left to right."""
    solid = alpha > THRESHOLD
    labels, count = ndi.label(ndi.binary_dilation(solid, iterations=MERGE_GAP))
    labels = labels * solid
    ids = list(range(1, count + 1))
    areas = np.array(ndi.sum(solid, labels, ids))
    big = [i for i, a in zip(ids, areas) if a > 0.05 * areas.max()]
    if len(big) != 3:
        raise SystemExit("expected 3 motifs, found %d" % len(big))
    centers = {i: ndi.center_of_mass(solid, labels, i)[1] for i in big}
    ordered = sorted(big, key=lambda i: centers[i])
    return [labels == i for i in ordered]


def cut(rgba, mask):
    ys, xs = np.nonzero(mask)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    side = int(round(max(y1 - y0, x1 - x0) * (1 + 2 * MARGIN)))
    cy, cx = (y0 + y1) / 2, (x0 + x1) / 2
    top, left = int(round(cy - side / 2)), int(round(cx - side / 2))
    canvas = np.zeros((side, side, 4), np.uint8)
    sy0, sx0 = max(top, 0), max(left, 0)
    sy1, sx1 = min(top + side, rgba.shape[0]), min(left + side, rgba.shape[1])
    piece = rgba[sy0:sy1, sx0:sx1].copy()
    piece[~mask[sy0:sy1, sx0:sx1]] = 0
    piece[..., :3] = tone(piece[..., :3].astype(float)).astype(np.uint8)
    canvas[sy0 - top:sy1 - top, sx0 - left:sx1 - left] = piece
    return Image.fromarray(canvas).convert("RGBa").resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=DEFAULT_SOURCE)
    parser.add_argument("--preview", default="")
    args = parser.parse_args()
    rgba = np.array(Image.open(args.source).convert("RGBA"))
    os.makedirs(OUT, exist_ok=True)
    images = []
    for name, mask in zip(NAMES, motifs(rgba[..., 3])):
        image = cut(rgba, mask)
        image.save(OUT + name + ".png", optimize=True)
        images.append(image)
        print("ok", name)
    if args.preview:
        sheet = Image.new("RGBA", (SIZE * 3 + 40, SIZE + 20), (22, 24, 32, 255))
        for n, image in enumerate(images):
            sheet.alpha_composite(image, (10 + n * (SIZE + 10), 10))
        sheet.save(args.preview)


if __name__ == "__main__":
    main()
