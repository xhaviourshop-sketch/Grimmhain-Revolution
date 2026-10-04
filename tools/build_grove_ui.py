"""Cuts the grove UI parts (seat ring, name plates, card frame, medallion, buttons) out of the AI-generated sheet (P5).

Repeatable: run from the repository root
    python tools/build_grove_ui.py [--source <png>] [--source2 <png>] [--preview <folder>] [--team-tiles <png>] [--team-tiles-only]
Reads ui-paket-v1.png and ui-paket-v2.png (1774x887, real alpha channel; v2 carries the night board parts: side tab, night bar,
role medallion, cartouche, round icon button, back plate) and writes
    godot/assets/ui/hain/*.png          the parts, prescaled to 2 texture pixels per logical unit
    godot/app/theme/grove_art_data.gd   measured geometry (hole centers, nine-slice margins), generated, do not edit by hand
Stretchable parts are assembled from end pieces and a short middle slice, so every edge is stretchable and the ornaments stay
protected. The left edge of the card is the mirrored right edge (the sheet's left edge carries the medallion). Resizing happens in
premultiplied alpha, so no color fringes appear at the edges.
The three team tile frames (village, wolves, solo; sheet team-kacheln.png) are cut by build_team_tiles() into
    godot/assets/ui/team_tile_*.webp    horizontal frames with a round socket on the left, stretchable between the ends
    godot/app/theme/team_tile_art_data.gd  end margins and socket geometry, generated, do not edit by hand
`--team-tiles-only` builds only these, leaving the hain parts (and their register hashes) untouched.
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
TEAM_DATA = ROOT + "/godot/app/theme/team_tile_art_data.gd"
TEAM_OUT = ROOT + "/godot/assets/ui/"
DEFAULT_TEAM_SOURCE = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/ui/team-kacheln.png"
DEFAULT_SOURCE2 = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/ui-paket-v2.png"

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
# sheet v2 (x0, y0, x1, y1), measured on the 1774x887 sheet
SIDE_TAB = (74, 31, 222, 855)     # vertical tab: spiked ends with ropes, plain bar between
NIGHT_BAR = (290, 114, 1741, 256)  # horizontal bar: ends, plain slices, clasp in the middle
CARTOUCHE = (352, 349, 1662, 516)  # horizontal plate with the moon on the left
ROLE_RING = (488, 567, 772, 836)   # silver ring with roots, transparent inside
ICON_ROUND = (906, 583, 1145, 823)  # round iron button with a silver rim
BACK_PLATE = (1325, 576, 1561, 822)  # small square plate with corner ornaments

SIDE_TAB_SCALE = 0.6              # tab about 44 logical units wide
SIDE_TAB_END = 210                # src px of each spiked end
NIGHT_BAR_SCALE = 0.7             # bar about 50 logical units high
NIGHT_BAR_LEFT = 250
NIGHT_BAR_RIGHT = 221
NIGHT_BAR_CLASP = (990, 1060)     # src x range of the middle clasp
NIGHT_BAR_MID1 = 700              # src x of the plain slice left of the clasp
NIGHT_BAR_MID2 = 1200             # src x of the plain slice right of the clasp
CARTOUCHE_SCALE = 0.42            # plate about 35 logical units high
CARTOUCHE_LEFT = 258
CARTOUCHE_RIGHT = 222
CARTOUCHE_MID = 800
RING_SCALE = 0.394                # ring 112 texture px = 56 logical units
ROUND_SCALE = 0.435               # round button 104 texture px = 52 logical units
BACK_SCALE = 0.47                 # square plate about 55 logical units
BACK_CORNER = 78                  # src px of each corner ornament
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


# team tile sheet (1774x887, real alpha): name, frame rows (y0, y1 of the solid part), socket center y and outer radius on the sheet
TEAM_TILES = (("village", 28, 274, 144), ("wolves", 318, 563, 443), ("solo", 591, 849, 733))
TEAM_SOCKET_X = 206               # socket center x on the sheet
TEAM_SOCKET_OUTER = 71            # outer radius of the socket ring
TEAM_SOCKET_HOLE = 60             # radius of the dark hole inside the ring (the role symbol sits here)
TEAM_PAD = 6                      # transparent border around each cut
TEAM_LEFT_END = 217               # src px from the cut's left edge: corner ornaments and the whole socket stay unstretched
TEAM_RIGHT_END = 130              # src px of the right corner ornaments
TEAM_MID_AT = 900                 # src x of the plain slice that gets stretched
TEAM_TILE_HEIGHT = 150            # texture px of the cut's height (2.7 px per logical unit at the 56 unit chip height)
TEAM_ALPHA_LOW, TEAM_ALPHA_HIGH = 40, 235  # the sheet's near-opaque body (alpha 245 to 253) becomes solid, its faint halo disappears


ARROW_SOURCE = ROOT + "/godot/assets/night/ui/arrow-left.png"  # bronze arrow of the P3 board, recolored to moon silver
SILVER = np.array([0.80, 0.84, 0.92])


def silver_arrow():
    """The old bronze arrow as a moon-silver one: luminance kept (stretched to a bright range), hue replaced, alpha untouched."""
    arrow = np.asarray(Image.open(ARROW_SOURCE).convert("RGBA")).astype(float)
    grey = arrow[..., :3] @ np.array([0.299, 0.587, 0.114]) / 255.0
    solid = arrow[..., 3] > 128
    low, high = np.percentile(grey[solid], 2), np.percentile(grey[solid], 98)
    level = np.clip((grey - low) / max(high - low, 1e-3), 0.0, 1.0) * 0.75 + 0.25
    arrow[..., :3] = np.clip(level[..., None] * SILVER * 255.0, 0, 255)
    return Image.fromarray(arrow.astype(np.uint8))


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


def clean_team_tile(sheet, box):
    """One frame cut out of the sheet: halo ramped away, only the connected frame kept, edge colors taken from the solid frame (no fringes)."""
    x0, y0, x1, y1 = box
    rgba = np.asarray(sheet.crop(box)).astype(float)
    alpha = rgba[..., 3]
    ramp = np.clip((alpha - TEAM_ALPHA_LOW) / (TEAM_ALPHA_HIGH - TEAM_ALPHA_LOW), 0.0, 1.0)
    labels, count = ndi.label(ramp > 0.02)
    sizes = ndi.sum(ramp > 0.02, labels, range(1, count + 1))
    keep = labels == (1 + int(np.argmax(sizes)))
    ramp = ramp * keep
    solid = ramp > 0.98
    # transparent and edge pixels take the color of the nearest solid pixel
    _, (iy, ix) = ndi.distance_transform_edt(~solid, return_indices=True)
    rgb = rgba[..., :3].copy()
    edge = ~solid
    rgb[edge] = rgba[iy[edge], ix[edge], :3]
    out = np.dstack([rgb, np.round(ramp * 255.0)]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out)


def build_team_tiles(source):
    """The three team tile frames as WebP (left end | plain slice | right end) plus their geometry file."""
    sheet = Image.open(source).convert("RGBA")
    os.makedirs(TEAM_OUT, exist_ok=True)
    lines = ["class_name TeamTileArtData", "extends RefCounted",
             "## Gemessene Geometrie der Team-Kachelrahmen (godot/assets/ui/team_tile_*.webp). Erzeugt von tools/build_grove_ui.py, nicht von Hand ändern.",
             "## Die Texturen werden gleichmäßig auf die Höhe der Kachel skaliert; nur die Mitte zwischen den Enden wird gedehnt.",
             "## Je Team: Fassung (Mittelpunkt x, y und Loch-Radius als Anteil der Texturhöhe, x ab linker Kante) und Randbreiten.", ""]
    ends = {}
    for name, ty0, ty1, cy in TEAM_TILES:
        cut = (0, 0, sheet.width, 0)
        flat = np.asarray(sheet)[..., 3]
        solid_cols = np.nonzero((flat[ty0:ty1] >= TEAM_ALPHA_LOW).any(0))[0]
        box = (int(solid_cols.min()) - TEAM_PAD, ty0 - TEAM_PAD, int(solid_cols.max()) + 1 + TEAM_PAD, ty1 + TEAM_PAD)
        tile = clean_team_tile(sheet, box)
        mid = TEAM_MID_AT - box[0]
        parts = (tile.crop((0, 0, TEAM_LEFT_END, tile.height)), tile.crop((mid, 0, mid + MID, tile.height)),
                 tile.crop((tile.width - TEAM_RIGHT_END, 0, tile.width, tile.height)))
        scale = TEAM_TILE_HEIGHT / tile.height
        result = scaled(assemble(*parts), scale)
        result.save(TEAM_OUT + "team_tile_%s.webp" % name, lossless=True, quality=100, method=6)
        height = tile.height
        ends[name] = (result.width, result.height)
        lines.append("const %s_SOCKET := Vector3(%.4f, %.4f, %.4f)  ## Mitte x, Mitte y, Lochradius" % (
            name.upper(), (TEAM_SOCKET_X - box[0]) / height, (cy - box[1]) / height, TEAM_SOCKET_HOLE / height))
        lines.append("const %s_MARGINS := Vector4(%d, 0, %d, 0)  ## links, oben, rechts, unten in Texturpixeln (Höhe %d); nur die Mitte wird gedehnt" % (
            name.upper(), round(TEAM_LEFT_END * scale), round(TEAM_RIGHT_END * scale), TEAM_TILE_HEIGHT))
    with open(TEAM_DATA, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
    print("team tiles", ends)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=DEFAULT_SOURCE)
    parser.add_argument("--source2", default=DEFAULT_SOURCE2)
    parser.add_argument("--preview", default=None)
    parser.add_argument("--team-tiles", default=DEFAULT_TEAM_SOURCE)
    parser.add_argument("--team-tiles-only", action="store_true")
    args = parser.parse_args()
    if args.team_tiles_only:
        build_team_tiles(args.team_tiles)
        return
    sheet = Image.open(args.source).convert("RGBA")
    sheet2 = Image.open(args.source2).convert("RGBA")
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

    # side tab: spiked ends (top and bottom as drawn), plain bar between
    x0, y0, x1, y1 = SIDE_TAB
    mid_y = (y0 + y1) // 2 - MID // 2
    parts = (sheet2.crop((x0, y0, x1, y0 + SIDE_TAB_END)), sheet2.crop((x0, mid_y, x1, mid_y + MID)), sheet2.crop((x0, y1 - SIDE_TAB_END, x1, y1)))
    tab = Image.new("RGBA", (x1 - x0, SIDE_TAB_END * 2 + MID), (0, 0, 0, 0))
    tab.paste(parts[0], (0, 0))
    tab.paste(parts[1], (0, SIDE_TAB_END))
    tab.paste(parts[2], (0, SIDE_TAB_END + MID))
    scaled(tab, SIDE_TAB_SCALE).save(OUT + "side_tab.png", optimize=True)
    data["SIDE_TAB_MARGINS"] = "Vector4(0, %d, 0, %d)" % (round(SIDE_TAB_END * SIDE_TAB_SCALE), round(SIDE_TAB_END * SIDE_TAB_SCALE))

    # night bar: left end | plain | clasp | plain | right end; the clasp stays unstretched, the plain slices stretch
    x0, y0, x1, y1 = NIGHT_BAR
    cx0, cx1 = NIGHT_BAR_CLASP
    pieces = (sheet2.crop((x0, y0, x0 + NIGHT_BAR_LEFT, y1)), sheet2.crop((NIGHT_BAR_MID1, y0, NIGHT_BAR_MID1 + MID, y1)),
              sheet2.crop((cx0, y0, cx1, y1)), sheet2.crop((NIGHT_BAR_MID2, y0, NIGHT_BAR_MID2 + MID, y1)),
              sheet2.crop((x1 - NIGHT_BAR_RIGHT, y0, x1, y1)))
    bar = Image.new("RGBA", (sum(p.width for p in pieces), y1 - y0), (0, 0, 0, 0))
    cursor = 0
    for piece in pieces:
        bar.paste(piece, (cursor, 0))
        cursor += piece.width
    scaled(bar, NIGHT_BAR_SCALE).save(OUT + "night_bar.png", optimize=True)
    data["NIGHT_BAR_MARGINS"] = "Vector4(%d, 0, %d, 0)" % (round(NIGHT_BAR_LEFT * NIGHT_BAR_SCALE), round(NIGHT_BAR_RIGHT * NIGHT_BAR_SCALE))
    clasp_start = NIGHT_BAR_LEFT + MID
    data["NIGHT_BAR_CLASP"] = "Vector2(%d, %d)" % (round(clasp_start * NIGHT_BAR_SCALE), round((cx1 - cx0) * NIGHT_BAR_SCALE))

    # cartouche: moon end | plain | right end
    x0, y0, x1, y1 = CARTOUCHE
    parts = (sheet2.crop((x0, y0, x0 + CARTOUCHE_LEFT, y1)), sheet2.crop((CARTOUCHE_MID, y0, CARTOUCHE_MID + MID, y1)), sheet2.crop((x1 - CARTOUCHE_RIGHT, y0, x1, y1)))
    scaled(assemble(*parts), CARTOUCHE_SCALE).save(OUT + "cartouche.png", optimize=True)
    data["CARTOUCHE_MARGINS"] = "Vector4(%d, 0, %d, 0)" % (round(CARTOUCHE_LEFT * CARTOUCHE_SCALE), round(CARTOUCHE_RIGHT * CARTOUCHE_SCALE))

    # role medallion: silver ring with roots, the inside stays transparent (the role symbol is drawn behind it)
    ring_img = sheet2.crop(ROLE_RING)
    scaled(ring_img, RING_SCALE).save(OUT + "role_medallion.png", optimize=True)
    rx, ry, rr = hole(np.asarray(ring_img)[..., 3], (ring_img.width // 2, ring_img.height // 2))
    data["ROLE_MEDALLION_HOLE_CENTER"] = "Vector2(%.4f, %.4f)" % (rx / ring_img.width, ry / ring_img.height)
    data["ROLE_MEDALLION_HOLE_RADIUS"] = "%.4f" % (rr / ring_img.width)
    data["ROLE_MEDALLION_ASPECT"] = "%.4f" % (ring_img.height / ring_img.width)

    # round icon button and back plate
    scaled(sheet2.crop(ICON_ROUND), ROUND_SCALE).save(OUT + "icon_button_round.png", optimize=True)
    scaled(sheet2.crop(BACK_PLATE), BACK_SCALE).save(OUT + "back_plate.png", optimize=True)
    data["BACK_PLATE_MARGINS"] = "Vector4(%d, %d, %d, %d)" % ((round(BACK_CORNER * BACK_SCALE),) * 4)

    left_arrow = silver_arrow()
    left_arrow.save(OUT + "arrow_left.png", optimize=True)
    mirrored(left_arrow).save(OUT + "arrow_right.png", optimize=True)

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
    build_team_tiles(args.team_tiles)
    print("ok", data)


if __name__ == "__main__":
    main()
