"""Builds the start-screen media in godot/assets/start/ from the ChatGPT originals in
C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/start/ (start-hintergrund.png, start-nebel.png, start-logo.png).
Run from the repo root: python tools/build_start_assets.py
 - hintergrund: WebP, unchanged size (1536 px wide)
 - logo: cropped to its alpha box, 1600 px wide, WebP with alpha
 - nebel: colour fringes removed (colour re-grown from the opaque fog), alpha softened and faded to the top/bottom edge,
   cropped to the fog band, cross-faded at the seam so it repeats without a visible edge, WebP with alpha
"""
import numpy as np
from PIL import Image, ImageFilter

SRC = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/start/"
OUT = "godot/assets/start/"


def blur(arr, r):
    img = Image.fromarray(arr)
    return np.asarray(img.filter(ImageFilter.GaussianBlur(r))).astype(np.float32)


bg = Image.open(SRC + "start-hintergrund.png").convert("RGB")
bg.save(OUT + "start-hintergrund.webp", quality=88, method=6)

logo = Image.open(SRC + "start-logo.png").convert("RGBA")
box = logo.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
logo = logo.crop((max(box[0] - 12, 0), max(box[1] - 12, 0), min(box[2] + 12, logo.width), min(box[3] + 12, logo.height)))
logo = logo.resize((1600, round(logo.height * 1600 / logo.width)), Image.LANCZOS)
logo.save(OUT + "start-logo.webp", quality=92, alpha_quality=100, method=6)

fog = np.asarray(Image.open(SRC + "start-nebel.png").convert("RGBA")).astype(np.float32)
alpha = fog[..., 3]
rgb = fog[..., :3]
# colour field grown from the solid fog (premultiplied blur), then used wherever the fog is thin or missing
pre = np.dstack([rgb * (alpha[..., None] / 255.0), alpha]).astype(np.uint8)
parts = [blur(pre[..., i], 14) for i in range(4)]
field = np.dstack(parts[:3]) / np.maximum(parts[3][..., None] / 255.0, 0.02)
weight = np.clip(alpha / 160.0, 0, 1)[..., None]
rgb = rgb * weight + np.clip(field, 0, 255) * (1 - weight)
# soften alpha: blur, gentle curve, fade to the band edges
a = blur(alpha.astype(np.uint8), 5) / 255.0
a = np.clip(a, 0, 1) ** 1.35
rows = np.where((a > 0.05).any(1))[0]
top, bottom = max(rows.min() - 30, 0), min(rows.max() + 30, a.shape[0])
a = a[top:bottom]
rgb = rgb[top:bottom]
h = a.shape[0]
fade = np.minimum(np.arange(h), np.arange(h)[::-1]) / 48.0
a = a * np.clip(fade, 0, 1)[:, None]
out = np.dstack([np.clip(rgb, 0, 255), a * 255.0]).astype(np.float32)
# seamless repeat: cross-fade the last `ov` columns into the first ones
ov = 200
w = out.shape[1]
t = (np.arange(ov) / ov)[None, :, None]
head = out[:, w - ov:, :] * (1 - t) + out[:, :ov, :] * t
seamless = np.concatenate([head, out[:, ov:w - ov, :]], axis=1)
Image.fromarray(np.clip(seamless, 0, 255).astype(np.uint8), "RGBA").save(OUT + "start-nebel.webp", quality=88, alpha_quality=95, method=6)
print("ok", bg.size, logo.size, seamless.shape)
