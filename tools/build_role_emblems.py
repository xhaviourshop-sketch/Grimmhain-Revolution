"""Cuts the 72 silver role emblems out of the AI-generated sheets (P6c, 3x3 grid per sheet, real alpha channel).

Repeatable: run from the repository root
    python tools/build_role_emblems.py [--source <folder>] [--preview <png>]
Reads symbole-01.png .. symbole-08.png and symbol-boegen-zuordnung.csv (bogen;position;zeile;spalte;rollen_id;...) from the source
folder and writes godot/assets/night/emblems/<rollen_id>.png (256x256, alpha kept).
Not cut by thirds: motifs may reach over the grid lines. Connected alpha regions (slightly dilated so thin gaps close) are found and each
gets the grid cell that holds its center of mass. Small detached pieces (flames, drops, splinters) join the nearest large region. Per role
all of its regions are cropped as one square, centered, with a little margin; pixels of neighbouring motifs inside that square are cleared.
Resizing happens in premultiplied alpha (no color fringes). Existing emblems are moved to emblems/_alt/ once (never deleted).
`--preview <png>` writes the control sheet (all emblems large and in bar size, role id below, dark ground).
Run `godot --path godot --import` afterwards so new files get their .import sidecars.
"""
import argparse
import csv
import os
import shutil

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = ROOT + "/godot/assets/night/emblems/"
DEFAULT_SOURCE = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/symbole/"
THRESHOLD = 24         # alpha above this counts as motif
MERGE_GAP = 5          # dilation iterations that close thin gaps inside one motif
SPECK_SHARE = 0.03     # a piece below this share that also lies far from the main body is a speck
SPECK_DISTANCE = 8     # px (source) between a speck and the main body
EDGE = 3              # px: a small piece this close to an inner grid line counts as clipped
STRAY_SHARE = 0.06     # only pieces below this share of the biggest piece can be strays
STRAY_TOLERANCE = -0.03 # a piece centered this far (share of the cell) outside the cell still counts as inside
CORE = 0.22            # half width of a cell's core, share of the cell size
MARGIN = 0.07          # extra border around the motif, share of its side
SIZE = 256


def cell_map(alpha, cell):
    """Per pixel the grid cell (0..8, row * 3 + col) that owns it, -1 for empty pixels.
    Connected regions (slightly dilated) that reach into the core of one cell belong to that cell as a whole. A region that touches the
    cores of several cells (motifs that touch or overlap) is split pixel by pixel by the nearest core. Regions without any core pixel
    (flames, drops, splinters, or a motif that avoids its cell center) go, pixel by pixel, to the cell of the nearest assigned pixel."""
    solid = alpha > THRESHOLD
    labels, count = ndi.label(ndi.binary_dilation(solid, iterations=MERGE_GAP))
    labels = labels * solid
    h, w = alpha.shape
    core = np.zeros((h, w), int) - 1
    half = CORE * cell
    for n in range(9):
        cy, cx = (n // 3 + 0.5) * cell, (n % 3 + 0.5) * cell
        core[int(cy - half):int(cy + half), int(cx - half):int(cx + half)] = n
    core[~solid] = -1
    owner = np.zeros((h, w), int) - 1
    split = []
    for i in range(1, count + 1):
        region = labels == i
        cells = np.unique(core[region & (core >= 0)])
        if len(cells) == 1:
            owner[region] = cells[0]
        elif len(cells) > 1:
            split.append(i)
    if split:
        _, idx = ndi.distance_transform_edt(core < 0, return_indices=True)
        nearest = core[idx[0], idx[1]]
        for i in split:
            region = labels == i
            owner[region] = nearest[region]
    if (owner >= 0).any():
        _, idx = ndi.distance_transform_edt(owner < 0, return_indices=True)
        nearest = owner[idx[0], idx[1]]
        rest = solid & (owner < 0)
        owner[rest] = nearest[rest]
    return owner


def drop_strays(mask, n, cell):
    """Removes small pieces whose center lies outside the role's own grid cell: leftovers of the neighbouring motif that were handed
    to this cell as the nearest assigned pixels. Flames, drops and splinters that belong to the motif stay (they lie in its cell)."""
    labels, count = ndi.label(ndi.binary_dilation(mask, iterations=MERGE_GAP))
    labels = labels * mask
    ids = list(range(1, count + 1))
    areas = np.array(ndi.sum(mask, labels, ids))
    centers = ndi.center_of_mass(mask.astype(float), labels, ids)
    y0, x0 = (n // 3) * cell - STRAY_TOLERANCE * cell, (n % 3) * cell - STRAY_TOLERANCE * cell
    y1, x1 = y0 + cell * (1 + 2 * STRAY_TOLERANCE), x0 + cell * (1 + 2 * STRAY_TOLERANCE)
    main = ids[int(areas.argmax())]
    far = ndi.distance_transform_edt(labels != main)
    keep = []
    for i, a, (cy, cx) in zip(ids, areas, centers):
        outside = not (y0 <= cy <= y1 and x0 <= cx <= x1)
        detached = a < SPECK_SHARE * areas.max() and far[labels == i].min() > SPECK_DISTANCE
        if a >= STRAY_SHARE * areas.max() or not (outside or detached):
            keep.append(i)
    mask = mask & np.isin(labels, keep)
    # small pieces clipped by an inner grid line are cut-off tips of a neighbouring motif
    fine, count = ndi.label(ndi.binary_dilation(mask, iterations=2))
    fine = fine * mask
    ids = list(range(1, count + 1))
    areas = np.array(ndi.sum(mask, fine, ids))
    top, left = round((n // 3) * cell), round((n % 3) * cell)
    bottom, right = round((n // 3 + 1) * cell), round((n % 3 + 1) * cell)
    drop = []
    for i, a in zip(ids, areas):
        if a >= SPECK_SHARE * areas.max():
            continue
        ys, xs = np.nonzero(fine == i)
        if (n // 3 > 0 and ys.min() <= top + EDGE) or (n // 3 < 2 and ys.max() >= bottom - 1 - EDGE)                 or (n % 3 > 0 and xs.min() <= left + EDGE) or (n % 3 < 2 and xs.max() >= right - 1 - EDGE):
            drop.append(i)
    return mask & ~np.isin(fine, drop)


def emblem(rgba, mask, n, cell):
    mask = drop_strays(mask, n, cell)
    ys, xs = np.nonzero(mask)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    side = int(round(max(y1 - y0, x1 - x0) * (1 + 2 * MARGIN)))
    cy, cx = (y0 + y1) / 2, (x0 + x1) / 2
    top, left = int(round(cy - side / 2)), int(round(cx - side / 2))
    canvas = np.zeros((side, side, 4), np.uint8)
    sy0, sx0 = max(top, 0), max(left, 0)
    sy1, sx1 = min(top + side, rgba.shape[0]), min(left + side, rgba.shape[1])
    piece = rgba[sy0:sy1, sx0:sx1].copy()
    piece[~mask[sy0:sy1, sx0:sx1]] = 0  # neighbouring motifs inside the square are cleared
    canvas[sy0 - top:sy1 - top, sx0 - left:sx1 - left] = piece
    return Image.fromarray(canvas).convert("RGBa").resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")


def preview(rows, path):
    """Control sheet: 9 columns, each role large (150 px) and in bar size (40 px) on dark ground, id below."""
    from PIL import ImageDraw
    cols, big, small, gap = 9, 150, 40, 14
    cell_w, cell_h = big + gap, big + small + 54
    ids = sorted(r["rollen_id"] for r in rows)
    sheet = Image.new("RGBA", (cols * cell_w + gap, ((len(ids) + cols - 1) // cols) * cell_h + gap), (22, 24, 32, 255))
    draw = ImageDraw.Draw(sheet)
    for n, rid in enumerate(ids):
        x, y = gap + (n % cols) * cell_w, gap + (n // cols) * cell_h
        image = Image.open(OUT + rid + ".png").convert("RGBA")
        sheet.alpha_composite(image.resize((big, big), Image.LANCZOS), (x, y))
        sheet.alpha_composite(image.resize((small, small), Image.LANCZOS), (x + (big - small) // 2, y + big + 6))
        draw.text((x, y + big + small + 14), rid[:24], fill=(200, 205, 216, 255))
    sheet.convert("RGB").save(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=DEFAULT_SOURCE)
    parser.add_argument("--preview", default=None)
    args = parser.parse_args()
    with open(args.source + "symbol-boegen-zuordnung.csv", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    old = [f for f in os.listdir(OUT) if f.endswith(".png") or f.endswith(".png.import")]
    alt = OUT + "_alt/"
    if not os.path.isdir(alt):
        os.makedirs(alt)
        for name in old:
            shutil.move(OUT + name, alt + name)
    problems = []
    done = 0
    for sheet_name in sorted({r["bogen"] for r in rows}):
        sheet = Image.open(args.source + sheet_name).convert("RGBA")
        rgba = np.asarray(sheet)
        cell = sheet.width / 3.0
        owner = cell_map(rgba[..., 3], cell)
        for r in (r for r in rows if r["bogen"] == sheet_name):
            n = (int(r["zeile"]) - 1) * 3 + int(r["spalte"]) - 1
            mask = owner == n
            if mask.sum() < 500:
                problems.append("%s: %s ohne Motiv" % (sheet_name, r["rollen_id"]))
                continue
            emblem(rgba, mask, n, cell).save(OUT + r["rollen_id"] + ".png", optimize=True)
            done += 1
    if args.preview:
        preview(rows, args.preview)
    print("zugeschnitten:", done)
    for p in problems:
        print("HINWEIS", p)


if __name__ == "__main__":
    main()
