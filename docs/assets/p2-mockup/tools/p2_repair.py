"""P2 repairs from the existing parts (scratch tool). Output: docs/assets/p2-mockup/parts/ and night-icons-circle/."""
import os, glob, math, sys
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFilter

WK = "C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Werwolf/Grimmhain Assets/"
REPO = "C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui/docs/assets/p2-mockup/"
PARTS = REPO + "parts/"
os.makedirs(PARTS, exist_ok=True)


def crop_alpha(im, pad=2):
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 8)
    return im.crop((max(0, xs.min() - pad), max(0, ys.min() - pad), xs.max() + 1 + pad, ys.max() + 1 + pad))


def largest_component(alpha, thr=16, grow=9):
    m = (alpha > thr).astype(np.uint8)
    m2 = cv2.dilate(m, np.ones((grow, grow), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m2)
    best = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    return (lab == best) & (m > 0)


# ---- slots: remove specks, fill the baked checker plinth dark, remove light halo ----
def clean_slot(name, red_glow):
    im = Image.open(WK + "nightorder-slot-%s.png" % name).convert("RGBA")
    arr = np.asarray(im).copy()
    a = arr[..., 3].astype(np.float32)
    keep = largest_component(arr[..., 3])
    arr[~keep, 3] = 0
    rgb = arr[..., :3].astype(np.float32)
    mx, mn = rgb.max(2), rgb.min(2)
    # baked checker plinth: light, low saturation, big component in the upper part
    light = ((mn > 140) & ((mx - mn) < 45) & (arr[..., 3] > 0)).astype(np.uint8)
    light = cv2.morphologyEx(light, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    n, lab, st, cen = cv2.connectedComponentsWithStats(light)
    plinth = np.zeros(light.shape, bool)
    for i in range(1, n):
        x, y, w, h, ar = st[i]
        if ar > 8000 and 0.7 < w / h < 1.4 and y + h < arr.shape[0] * 0.3:
            plinth |= lab == i
    plinth = cv2.dilate(plinth.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
    arr[plinth, :3] = (14, 16, 22)
    arr[plinth, 3] = 255
    # outer halo: light/pink fringe on the outer boundary
    alpha = arr[..., 3]
    solid = (alpha > 16).astype(np.uint8)
    inner = cv2.erode(solid, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (31, 31)))
    outer_band = (solid == 1) & (inner == 0)
    rgb = arr[..., :3].astype(np.float32)
    whitish = np.minimum(rgb[..., 1], rgb[..., 2]) > (70 if red_glow else 110)
    kill = outer_band & whitish
    arr[kill, 3] = 0
    # re-clean after cutting and soften the new edge by 1px
    keep = largest_component(arr[..., 3])
    arr[~keep, 3] = 0
    a2 = cv2.GaussianBlur(arr[..., 3].astype(np.float32), (0, 0), 0.8)
    arr[..., 3] = np.where(arr[..., 3] > 0, np.minimum(arr[..., 3], 255), 0)
    arr[..., 3] = np.clip(np.minimum(a2 * 1.15, arr[..., 3]), 0, 255).astype(np.uint8)
    out = crop_alpha(Image.fromarray(arr))
    out.save(PARTS + "slot-%s.png" % name)
    print("slot", name, out.size, "plinth px", int(plinth.sum()))


# ---- action frame: transparent plate ----
def clean_frame():
    im = Image.open(WK + "action-frame-night.png").convert("RGBA")
    arr = np.asarray(im).copy()
    rgb = arr[..., :3].astype(np.float32)
    dark = ((rgb.max(2) < 20) & (arr[..., 3] > 200)).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(dark)
    for i in range(1, n):
        x, y, w, h, ar = st[i]
        if ar > 6000 and w > h * 1.5:
            m = (lab == i)
            m = cv2.dilate(m.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
            arr[m, 3] = 0
            print("frame plate", x, y, w, h, ar)
    out = crop_alpha(Image.fromarray(arr))
    out.save(PARTS + "action-frame-night.png")
    print("frame", out.size)


# ---- tabs ----
def tabs():
    src = Image.open(WK + "panel-protocol-tab.png").convert("RGBA")
    t = crop_alpha(src)
    t.save(PARTS + "tab-protocol.png")
    print("tab-protocol", t.size)
    arr = np.asarray(t).copy()
    h, w = arr.shape[:2]
    # book emblem region: find via darkness/colour contrast around the centre
    cy = h // 2
    box = (int(w * 0.12), int(cy - w * 0.62), int(w * 0.88), int(cy + w * 0.62))
    return t, box


if __name__ == "__main__":
    for n, red in (("active", True), ("done", False), ("inactive", False)):
        clean_slot(n, red)
    clean_frame()
    t, box = tabs()
    print(t.size, box)


def options_tab():
    t = Image.open(PARTS + "tab-protocol.png").convert("RGBA")
    arr = np.asarray(t).copy()
    mask = np.zeros(arr.shape[:2], np.uint8)
    mask[708:812, 40:162] = 255
    bgr = cv2.cvtColor(arr[..., :3], cv2.COLOR_RGB2BGR)
    patch = arr[400:400 + 124, 38:164, :3].copy()
    m = np.zeros((124, 126), np.float32)
    m[8:-8, 8:-8] = 1.0
    m = cv2.GaussianBlur(m, (0, 0), 3.5)[..., None]
    arr[698:822, 38:164, :3] = (patch * m + arr[698:822, 38:164, :3] * (1 - m)).astype(np.uint8)
    base = Image.fromarray(arr)
    S = 6
    R = 52
    g = Image.new("RGBA", (R * 2 * S + 40, R * 2 * S + 40), (0, 0, 0, 0))
    cx = cy = g.width // 2
    n = 8
    pts = []
    for i in range(n * 4):
        a0 = 2 * math.pi * i / (n * 4)
        r = R * S if (i % 4) in (0, 1) else 0.8 * R * S
        pts.append((cx + r * math.cos(a0), cy + r * math.sin(a0)))
    mk = Image.new("L", g.size, 0)
    d = ImageDraw.Draw(mk)
    d.polygon(pts, fill=255)
    d.ellipse((cx - 17 * S, cy - 17 * S, cx + 17 * S, cy + 17 * S), fill=0)
    # gold shading: diagonal gradient, darker rim
    gy, gx = np.mgrid[0:g.height, 0:g.width].astype(np.float32)
    t01 = np.clip(((gx + gy) / (g.width + g.height)), 0, 1)
    gold_hi = np.array([226, 190, 98], np.float32)
    gold_lo = np.array([112, 84, 36], np.float32)
    col = gold_lo[None, None] * t01[..., None] + gold_hi[None, None] * (1 - t01[..., None])
    gold = Image.fromarray(np.dstack([col, np.full(t01.shape, 255, np.float32)]).astype(np.uint8))
    gear = Image.new("RGBA", g.size, (0, 0, 0, 0))
    gear.paste(gold, (0, 0), mk)
    rim = mk.filter(ImageFilter.MinFilter(2 * S + 1))
    inner = Image.new("L", g.size, 0)
    inner.paste(mk, (0, 0))
    edge = Image.fromarray((np.asarray(mk, np.int16) - np.asarray(rim, np.int16)).clip(0, 255).astype(np.uint8))
    dark = Image.new("RGBA", g.size, (28, 20, 10, 255))
    gear.paste(dark, (0, 0), edge)
    # inner ring groove
    gd = ImageDraw.Draw(gear)
    gd.ellipse((cx - 30 * S, cy - 30 * S, cx + 30 * S, cy + 30 * S), outline=(60, 44, 20, 255), width=2 * S)
    gear = gear.resize((g.width // S, g.height // S), Image.LANCZOS)
    cxp, cyp = 101, 760
    base.alpha_composite(gear, (cxp - gear.width // 2, cyp - gear.height // 2))
    base.save(PARTS + "tab-options.png")
    print("tab-options", base.size)


if __name__ == "__main__":
    options_tab()
