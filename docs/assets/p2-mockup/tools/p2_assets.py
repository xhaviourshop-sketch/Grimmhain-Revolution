"""P2 asset build: final faces, status badges, role emblems (magenta keyed). Scratch tool, output into docs/assets/p2-mockup/."""
import os, shutil, json
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFont

D = r"C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/"
SC = r"C:/Users/Marku/AppData/Local/Temp/claude/C--Users-Marku-Desktop-Grimmhain-Grimmhain---Revolution/0dbb4350-77d8-481f-8ba2-e35a00044365/scratchpad/"
REPO = r"C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui/docs/assets/p2-mockup/"
V3 = D + "mockup-v3/"
for p in (REPO + "faces", REPO + "badges", REPO + "emblems", V3):
    os.makedirs(p, exist_ok=True)

# ---- 1. faces ----
FINAL = ["A1", "A2", "A3", "A4", "A5", "A6", "B1", "B2", "B3", "B5", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8",
         "D1", "D2", "D3", "D4", "D7", "D8"]
for i, n in enumerate(FINAL):
    shutil.copy(SC + "cand/%s.png" % n, REPO + "faces/face-%02d.png" % (i + 1))
cols, T = 6, 256
sheet = Image.new("RGB", (cols * T, 4 * T), (20, 22, 29))
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype("arial.ttf", 34)
for i, n in enumerate(FINAL):
    x, y = (i % cols) * T, (i // cols) * T
    sheet.paste(Image.open(SC + "cand/%s.png" % n), (x, y))
    d.text((x + 8, y + 4), "%d" % (i + 1), fill=(255, 255, 0), font=font, stroke_width=3, stroke_fill=(0, 0, 0))
    d.text((x + T - 52, y + T - 38), n, fill=(210, 210, 210), font=ImageFont.truetype("arial.ttf", 22), stroke_width=2, stroke_fill=(0, 0, 0))
sheet.save(V3 + "P2-kontaktblatt-gesichter-24.png")


# ---- 2/3. magenta keying ----
def key_sheet(path, cols, rows, size_out, prefix, outdir, skip=()):
    im = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    h, w = im.shape[:2]
    R, G, B = im[..., 0], im[..., 1], im[..., 2]
    pink = np.minimum(R, B) - G  # ~255 on magenta, <=~60 on content
    bgmask = (pink > 140).astype(np.uint8)
    # keep only background connected to the sheet (so magenta-ish content inside medallions survives)
    n, lab = cv2.connectedComponents(bgmask)
    bg = np.zeros_like(bgmask)
    # background = components touching the border or large
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])))
    border.discard(0)
    for l in border:
        bg[lab == l] = 1
    # alpha via soft matting in a 3px band around the background
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    band = cv2.dilate(bg, k) - bg
    a = np.ones((h, w), np.float32)
    a[bg == 1] = 0.0
    soft = np.clip(1.0 - (pink - 40.0) / 190.0, 0, 1)
    a[band == 1] = soft[band == 1]
    a[(bg == 0) & (band == 0)] = 1.0
    # decontaminate: c = (obs - (1-a)*M) / a
    M = np.array([255, 0, 255], np.float32)
    out = im.copy()
    m = (band == 1) & (a > 0.04)
    out[m] = (im[m] - (1 - a[m, None]) * M) / a[m, None]
    out = np.clip(out, 0, 255)
    # remaining pink spill on edge pixels: clamp R,B to G-weighted limit
    sp = np.maximum(0, np.minimum(out[..., 0], out[..., 2]) - out[..., 1] - 25)
    sp[(band == 0)] = 0
    out[..., 0] -= sp * 0.7
    out[..., 2] -= sp * 0.7
    rgba = np.dstack([np.clip(out, 0, 255), a * 255]).astype(np.uint8)
    fg = (a > 0.5).astype(np.uint8)
    fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    n2, lab2, stats, cent = cv2.connectedComponentsWithStats(fg)
    comps = [i for i in range(1, n2) if stats[i, cv2.CC_STAT_AREA] > 5000]
    assert len(comps) == cols * rows, len(comps)
    comps.sort(key=lambda i: (int(cent[i][1] // (h / rows)), cent[i][0]))
    meta = []
    for idx, i in enumerate(comps, 1):
        x, y, bw, bh = [int(v) for v in stats[i][:4]]
        crop = Image.fromarray(rgba[y:y + bh, x:x + bw])
        side = max(bw, bh)
        sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        sq.paste(crop, ((side - bw) // 2, (side - bh) // 2))
        big = sq.resize((size_out, size_out), Image.LANCZOS)
        if idx not in skip:
            big.save(outdir + "%s-%02d.png" % (prefix, idx))
        meta.append((idx, side))
    return meta


m1 = key_sheet(D + "P2-03-status-badges-v1.png", 3, 2, 192, "badge", REPO + "badges/")
m2 = key_sheet(D + "P2-04-role-emblems-probe-v1.png", 4, 3, 256, "emblem", REPO + "emblems/", skip=(6,))
print(m1)
print(m2)
