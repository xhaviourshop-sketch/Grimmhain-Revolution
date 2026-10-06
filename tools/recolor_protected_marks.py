"""Recolor the gold protection marks (ring and shield badge) to moon blue (DA-104).

Only pixels with a gold, yellow or brown-red hue are turned; brightness, painting
and alpha stay. Safe to run repeatedly. build_assets.py calls this after a rebuild.

Target hue 212 degrees (ThemeTokens.TEAM_READ_VILLAGE #8cc4ff is about 209), with
clearly raised saturation: the moon-silver glow of the acting person is nearly
grey (#c5cddb, saturation about 0.1), so a saturated blue cannot be confused with it.
"""
import colorsys
import os
import sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = ["godot/assets/night/frames/ring-protected.png", "godot/assets/night/badges/badge-protected.png"]
TARGET_HUE = 212.0
MIN_SAT = 0.25   # below this a pixel is a grey or white highlight and stays untouched
GOLD_MAX = 75.0  # gold, yellow, orange, brown: 0..75 degrees
GOLD_MIN_RED = 340.0  # reddish edge pixels of the gold


def recolor(im):
    im = im.convert("RGBA")
    px = im.load()
    changed = 0
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            deg = h * 360
            if s < MIN_SAT or not (deg <= GOLD_MAX or deg >= GOLD_MIN_RED):
                continue
            ns = min(1.0, max(s, 0.55) * 1.1)
            # a slight drift keeps some variation from the painted gradient
            nh = (TARGET_HUE + (min(deg, 60.0) - 40.0) * 0.25) / 360
            nr, ng, nb = colorsys.hsv_to_rgb(nh, ns, v)
            px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
            changed += 1
    return im, changed


def leftovers(im):
    n = 0
    for r, g, b, a in im.getdata():
        if a > 0:
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s >= MIN_SAT and 30 <= h * 360 <= 70:
                n += 1
    return n


def main():
    for rel in FILES:
        path = os.path.join(ROOT, rel)
        im, changed = recolor(Image.open(path))
        im.save(path, optimize=True)
        print("%s: %d pixels turned, %d gold pixels left" % (rel, changed, leftovers(im)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
