#!/usr/bin/env python
"""Rewrites the painted value in the top left disc of the role cards from "5.0" to "5" (whole numbers shown without ".0").

Only the cards named in WHOLE are touched. For each card the gold glyphs are found by colour, the ".0" is painted over with the
disc background (inpainting) and the integer digit is moved to the centre of the old text, using the digit pixels of the same image
so that font, size and colour stay identical. Run from the repo root: python tools/fix_card_numbers.py [--check]
--check only lists what would change. Needs numpy, Pillow, opencv-python, scipy.
"""
import sys
import numpy as np
import cv2
from PIL import Image
from scipy import ndimage

WHOLE = ["doktor", "kartenschlucker", "kriegerin_des_lichts", "maertyrerin", "nekromant", "seelentauscher", "traumdeuter", "werwolf"]
LANGS = ["de", "en"]


def goldness(rgb: np.ndarray) -> np.ndarray:
    r, g, b = [rgb[..., i].astype(np.float32) for i in range(3)]
    return np.clip((g - b - 30.0) / 50.0, 0.0, 1.0) * np.clip((r - 110.0) / 40.0, 0.0, 1.0)


def process(path: str, check: bool) -> bool:
    img = Image.open(path).convert("RGB")
    rgb = np.array(img)
    h, w = rgb.shape[:2]
    box = (slice(0, int(h * 0.14)), slice(0, int(w * 0.30)))
    gold = goldness(rgb[box])
    mask = gold > 0.5
    labels, count = ndimage.label(ndimage.binary_dilation(mask, iterations=1))
    comps = []
    for i in range(1, count + 1):
        ys, xs = np.where((labels == i) & mask)
        if len(xs) >= 12:
            comps.append((xs.min(), xs.max(), ys.min(), ys.max(), len(xs), i))
    comps.sort()
    if len(comps) != 3 or comps[1][4] > comps[0][4] * 0.3:
        print(f"SKIP {path}: expected digit, dot, digit, found {len(comps)} parts")
        return False
    if check:
        print(f"would fix {path}")
        return True
    x0, x1 = comps[0][0], comps[2][1]
    y0, y1 = min(c[2] for c in comps), max(c[3] for c in comps)
    pad = 4
    full = np.zeros(rgb.shape[:2], np.uint8)
    ys, xs = np.where(mask)
    full[ys, xs] = 255
    text_area = np.zeros_like(full)
    text_area[max(y0 - pad, 0):y1 + pad + 1, max(x0 - pad, 0):x1 + pad + 1] = 255
    erase = cv2.dilate(full & text_area, np.ones((7, 7), np.uint8))
    clean = cv2.inpaint(rgb, erase, 5, cv2.INPAINT_TELEA)
    dx0, dx1, dy0, dy1, _, digit_label = comps[0]
    gx0, gx1 = dx0 - pad, dx1 + pad
    gy0, gy1 = dy0 - pad, dy1 + pad
    # only the pixels of the digit itself, so a dot or the next glyph close by is not copied along
    own = ndimage.binary_dilation(labels == digit_label, iterations=2)
    own_full = np.zeros(rgb.shape[:2], bool)
    own_full[box] = own
    alpha = (np.clip(goldness(rgb[gy0:gy1 + 1, gx0:gx1 + 1]) * 1.2, 0.0, 1.0) * own_full[gy0:gy1 + 1, gx0:gx1 + 1])[..., None]
    shift = int(round((x0 + x1) / 2.0 - (dx0 + dx1) / 2.0))
    out = clean.astype(np.float32)
    ty0, tx0 = gy0, gx0 + shift
    region = out[ty0:ty0 + alpha.shape[0], tx0:tx0 + alpha.shape[1]]
    glyph = rgb[gy0:gy1 + 1, gx0:gx1 + 1].astype(np.float32)
    region[:] = region * (1.0 - alpha) + glyph * alpha
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(path, "WEBP", quality=92, method=6)
    print(f"fixed {path} (shift {shift}px)")
    return True


def main() -> None:
    check = "--check" in sys.argv
    done = 0
    for lang in LANGS:
        for name in WHOLE:
            done += process(f"godot/assets/cards/{lang}/{name}.webp", check)
    print(f"{done} of {len(WHOLE) * len(LANGS)} cards")


if __name__ == "__main__":
    main()
