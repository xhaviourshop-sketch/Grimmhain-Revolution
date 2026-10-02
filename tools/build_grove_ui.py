"""Cuts the grove UI parts (seat ring, name plates, card frame, medallion, buttons) out of the AI-generated sheet (P5).

Repeatable: run from the repository root
    python tools/build_grove_ui.py [--source <png>] [--preview <folder>]
Reads ui-paket-v1.png (1774x887, real alpha channel) and writes
    godot/assets/ui/hain/*.png          the parts, prescaled to 2 texture pixels per logical unit
    godot/app/theme/grove_art_data.gd   measured geometry (hole centers, nine-slice margins), generated, do not edit by hand
Stretchable parts are assembled from end pieces and a short middle slice, so every edge is stretchable and the ornaments stay
protected. The left edge of the card is the mirrored right edge (the sheet's left edge carries the medallion). Resizing happens in
premultiplied alpha, so no color fringes appear at the edges.
Run `godot --path godot --import` afterwards so new files get their .import sidecars.
"""
import argparse
import os

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = ROOT + "/godot/assets/ui/hain/"
DATA = ROOT + "/godot/app/theme/grove_art_data.gd"
DEFAULT_SOURCE = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/ui-paket-v1.png"

# regions of the sheet (x0, y0, x1, y1), measured on the 1774x887 sheet
SEAT = (31, 32, 532, 493)         # silver ring with roots and number socket at the upper left
CARD = (584, 43, 1750, 487)       # action card frame (medallion on the left, rebuilt)
PLATE = (295, 534, 1480, 651)     # name plate with spikes
RED = (32, 694, 846, 838)
DARK = (928, 694, 1742, 838)
HOLE_SEED = (289, 277)            # a point inside the seat ring's hole
SOCKET_SEED = (118, 121)          # a point inside the number socket's hole

MEDALLION_SCALE = 0.5            # medallion ring about 100 logical units
SEAT_SCALE = 0.415                # seat ring 208 px wide: sharp up to 104 logical units at 2x
PLATE_SCALE = 0.44                # bar about 20 logical units high at 2 px per unit
BUTTON_SCALE = 0.56               # button plate about 40 logical units high (the touch area is 56, the plate is centered in it)
CARD_SCALE = 0.63                 # card corners about 60 logical units
SHORT_PLATE_CAP = 40              # src px of each end of the short plate (iron cap)
SHORT_PLATE_START = 462           # src x where the left iron cap begins
SHORT_PLATE_ROWS = (549, 641)     # src rows of the bar including the caps
LONG_END = 185
BUTTON_END = 175
CARD_END = 190
MID = 60                          # src px of the stretchable middle slice
MEDALLION_CENTER = (740, 270)     # center of the card's medallion on the sheet
MEDALLION_RADIUS = 140
MEDALLION_CUT_X = 20              # crop columns left of this belong to the card frame bar, not to the medallion
CARD_FILL = (18, 21, 23)          # the card's flat dark fill around the medallion


def scaled(image, scale):
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    return image.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA")


def assemble(left, mid, right):
    """left | mid | right as one image (all the same height)."""
    out = Image.new("RGBA", (left.width + mid.width + right.width, left.height), (0, 0, 0, 0))
    out.paste(left, (0, 0))
    out.paste(mid, (left.width, 0))
    out.paste(right, (left.width + mid.width, 0))
    return out


def mirrored(image):
    return image.transpose(Image.FLIP_LEFT_RIGHT)


def medallion(sheet):
    """The card's round medallion ring: the flat dark card fill around it is removed (flood from the outside), the frame bar is cut."""
    cx, cy = MEDALLION_CENTER
    r = MEDALLION_RADIUS
    box = np.asarray(sheet.crop((cx - r, cy - r, cx + r, cy + r))).copy()
    yy, xx = np.ogrid[:2 * r, :2 * r]
    disc = ((xx - r) ** 2 + (yy - r) ** 2) <= r * r
    diff = np.abs(box[..., :3].astype(int) - np.array(CARD_FILL)).max(-1)
    near = (diff <= 10) & (box[..., 3] > 200)
    labels, _ = ndi.label(near & disc)
    border = disc & ~ndi.binary_erosion(disc)
    touching = np.unique(labels[border & near])
    outside = np.isin(labels, touching[touching > 0])
    # a thin fringe of fill-colored pixels next to the removed area goes too
    fringe = ndi.binary_dilation(outside, iterations=2) & (diff <= 24) & (box[..., 3] > 200)
    keep = disc & ~outside & ~fringe & (xx >= MEDALLION_CUT_X)
    keep = ndi.binary_opening(keep | (box[..., 3] < 10) & disc, iterations=1) & disc & (xx >= MEDALLION_CUT_X) & ~outside & ~fringe
    labels, count = ndi.label(keep)
    sizes = ndi.sum(keep, labels, range(1, count + 1))
    keep = np.isin(labels, [i + 1 for i, size in enumerate(sizes) if size >= 400])  # drop specks
    soft = ndi.gaussian_filter(keep.astype(float), 0.8)  # feathered edge, no hard pixel staircase
    box[..., 3] = np.minimum(box[..., 3], np.round(soft * 255)).astype(np.uint8)
    image = Image.fromarray(box)
    bbox = image.getchannel("A").getbbox()
    return image.crop(bbox)


def hole(alpha, seed):
    labels, _ = ndi.label(alpha < 10)
    mask = labels == labels[seed[1], seed[0]]
    ys, xs = np.nonzero(mask)
    return float(xs.mean()), float(ys.mean()), float(np.sqrt(mask.sum() / np.pi))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=DEFAULT_SOURCE)
    parser.add_argument("--preview", default=None)
    args = parser.parse_args()
    sheet = Image.open(args.source).convert("RGBA")
    os.makedirs(OUT, exist_ok=True)
    data = {}

    # seat ring and medallion
    seat = sheet.crop(SEAT)
    alpha = np.asarray(seat)[..., 3]
    hx, hy, hr = hole(alpha, (HOLE_SEED[0] - SEAT[0], HOLE_SEED[1] - SEAT[1]))
    sx, sy, sr = hole(alpha, (SOCKET_SEED[0] - SEAT[0], SOCKET_SEED[1] - SEAT[1]))
    scaled(seat, SEAT_SCALE).save(OUT + "seat_frame.png", optimize=True)
    ring = medallion(sheet)
    scaled(ring, MEDALLION_SCALE).save(OUT + "card_medallion.png", optimize=True)
    mx, my, mr = hole(np.asarray(ring)[..., 3], (ring.width // 2, ring.height // 2))
    data["MEDALLION_HOLE_CENTER"] = "Vector2(%.4f, %.4f)" % (mx / ring.width, my / ring.height)
    data["MEDALLION_HOLE_RADIUS"] = "%.4f" % (mr / ring.width)
    data["MEDALLION_ASPECT"] = "%.4f" % (ring.height / ring.width)
    data["SEAT_HOLE_CENTER"] = "Vector2(%.4f, %.4f)" % (hx / seat.width, hy / seat.height)
    data["SEAT_HOLE_RADIUS"] = "%.4f" % (hr / seat.width)
    data["SEAT_SOCKET_CENTER"] = "Vector2(%.4f, %.4f)" % (sx / seat.width, sy / seat.height)
    data["SEAT_SOCKET_RADIUS"] = "%.4f" % (sr / seat.width)
    data["SEAT_ASPECT"] = "%.4f" % (seat.height / seat.width)

    # short name plate: iron caps at both ends (left one mirrored), plain bar between
    rows = SHORT_PLATE_ROWS
    left = sheet.crop((SHORT_PLATE_START, rows[0], SHORT_PLATE_START + SHORT_PLATE_CAP, rows[1]))
    mid = sheet.crop((700, rows[0], 700 + MID, rows[1]))
    short = scaled(assemble(left, mid, mirrored(left)), PLATE_SCALE)
    short.save(OUT + "name_plate_short.png", optimize=True)
    cap = round(SHORT_PLATE_CAP * PLATE_SCALE)
    data["NAME_PLATE_SHORT_MARGINS"] = "Vector4(%d, 0, %d, 0)" % (cap, cap)

    # long name plate: spiked ends as drawn
    lx0, ly0, lx1, ly1 = PLATE
    end = LONG_END
    parts = (sheet.crop((lx0, ly0, lx0 + end, ly1)), sheet.crop((700, ly0, 700 + MID, ly1)), sheet.crop((lx1 - end, ly0, lx1, ly1)))
    scaled(assemble(*parts), PLATE_SCALE).save(OUT + "name_plate_long.png", optimize=True)
    data["NAME_PLATE_LONG_MARGINS"] = "Vector4(%d, 0, %d, 0)" % (round(end * PLATE_SCALE), round(end * PLATE_SCALE))

    # buttons
    for name, box in (("button_primary", RED), ("button_secondary", DARK)):
        x0, y0, x1, y1 = box
        mid_x = (x0 + x1) // 2 - MID // 2
        parts = (sheet.crop((x0, y0, x0 + BUTTON_END, y1)), sheet.crop((mid_x, y0, mid_x + MID, y1)), sheet.crop((x1 - BUTTON_END, y0, x1, y1)))
        scaled(assemble(*parts), BUTTON_SCALE).save(OUT + name + ".png", optimize=True)
        data[name.upper() + "_MARGINS"] = "Vector4(%d, 30, %d, 30)" % (round(BUTTON_END * BUTTON_SCALE), round(BUTTON_END * BUTTON_SCALE))

    # card frame: the right edge mirrored to the left, so all edges are stretchable and the medallion is gone
    x0, y0, x1, y1 = CARD
    right_edge = sheet.crop((x1 - CARD_END, y0, x1, y1))
    mid_x = (x0 + x1) // 2 + 100
    card = scaled(assemble(mirrored(right_edge), sheet.crop((mid_x, y0, mid_x + MID, y1)), right_edge), CARD_SCALE)
    card.save(OUT + "card_frame.png", optimize=True)
    data["CARD_FRAME_MARGINS"] = "Vector4(%d, 90, %d, 90)" % (round(CARD_END * CARD_SCALE), round(CARD_END * CARD_SCALE))

    lines = ["class_name GroveArtData", "extends RefCounted",
             "## Gemessene Geometrie der Hain-Oberflächenteile (godot/assets/ui/hain/). Erzeugt von tools/build_grove_ui.py, nicht von Hand ändern.",
             "## Ränder (Vector4: links, oben, rechts, unten) in Texturpixeln; die Texturen haben 2 Pixel je logische Einheit (Faktor TEXTURE_SCALE).", "",
             "const TEXTURE_SCALE := 2.0"]
    for key, value in data.items():
        lines.append("const %s := %s" % (key, value))
    with open(DATA, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")

    if args.preview:
        os.makedirs(args.preview, exist_ok=True)
        for fname in sorted(os.listdir(OUT)):
            if fname.endswith(".png"):
                part = Image.open(OUT + fname)
                for tone, color in (("hell", (200, 215, 200, 255)), ("dunkel", (25, 25, 30, 255))):
                    bg = Image.new("RGBA", part.size, color)
                    bg.alpha_composite(part)
                    bg.save(os.path.join(args.preview, "%s-%s.png" % (fname[:-4], tone)))
    print("ok", data)


if __name__ == "__main__":
    main()
