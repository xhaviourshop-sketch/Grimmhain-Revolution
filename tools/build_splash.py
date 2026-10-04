"""SUPERSEDED by tools/build_brand_assets.py (wordmark + seal splash); do not run, it would overwrite the new splash.
Builds godot/assets/app/splash-grimmhain.png (boot splash and web loading page): start-hintergrund strongly darkened with a vignette
towards the splash colour, start-logo centred. Needs godot/assets/start/ (python tools/build_start_assets.py).
Run from the repo root: python tools/build_splash.py"""
from PIL import Image, ImageEnhance
import numpy as np

W, H = 1536, 1152
BG = (6, 8, 16)
src = Image.open("godot/assets/start/start-hintergrund.webp").convert("RGB")
scale = H / src.height
src = src.resize((round(src.width * scale), H), Image.LANCZOS)
left = (src.width - W) // 2
img = ImageEnhance.Brightness(src.crop((left, 0, left + W, H))).enhance(0.3)
arr = np.asarray(img).astype(np.float32)
yy, xx = np.mgrid[0:H, 0:W]
d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
mask = np.clip((d - 0.5) / 0.5, 0, 1)[..., None] ** 1.2
arr = arr * (1 - mask) + np.array(BG, dtype=np.float32) * mask
img = Image.fromarray(arr.astype(np.uint8)).convert("RGBA")
logo = Image.open("godot/assets/start/start-logo.webp").convert("RGBA")
logo = logo.resize((1000, round(logo.height * 1000 / logo.width)), Image.LANCZOS)
img.alpha_composite(logo, ((W - logo.width) // 2, int(H * 0.44 - logo.height / 2)))
img.convert("RGB").save("godot/assets/app/splash-grimmhain.png", optimize=True)
print("ok", img.size)
