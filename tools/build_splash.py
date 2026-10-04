"""Builds godot/assets/app/splash-grimmhain.png: night scene (scene-night-base), darkened, vignette to the splash colour,
title "GRIMMHAIN" in moon silver. Run from the repo root: python tools/build_splash.py"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance
import numpy as np

W, H = 1536, 1152
BG = (6, 8, 16)
SILVER = (197, 205, 219)
src = Image.open("godot/assets/night/bg/scene-night-base.webp").convert("RGB")
scale = H / src.height
src = src.resize((round(src.width * scale), H), Image.LANCZOS)
left = (src.width - W) // 2
img = ImageEnhance.Brightness(src.crop((left, 0, left + W, H))).enhance(0.42)
arr = np.asarray(img).astype(np.float32)
yy, xx = np.mgrid[0:H, 0:W]
d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
mask = np.clip((d - 0.55) / 0.45, 0, 1)[..., None] ** 1.3
arr = arr * (1 - mask) + np.array(BG, dtype=np.float32) * mask
img = Image.fromarray(arr.astype(np.uint8))

font = ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", 150)
text = "GRIMMHAIN"
track = 14
widths = [font.getlength(c) for c in text]
total = sum(widths) + track * (len(text) - 1)
x0 = (W - total) / 2
y0 = H * 0.40
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ld = ImageDraw.Draw(layer)
x = x0
for c, w in zip(text, widths):
    gd.text((x, y0), c, font=font, fill=SILVER + (170,))
    ld.text((x, y0), c, font=font, fill=SILVER + (255,))
    x += w + track
glow = glow.filter(ImageFilter.GaussianBlur(22))
img = Image.alpha_composite(img.convert("RGBA"), glow)
img = Image.alpha_composite(img, layer).convert("RGB")
img.save("godot/assets/app/splash-grimmhain.png", optimize=True)
print("ok", img.size)
