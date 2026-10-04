"""Builds the brand media from C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/marke/ (wortmarke.png, siegel.png):
 - godot/assets/brand/wortmarke.webp, siegel.webp (cropped to alpha box)
 - godot/assets/app/app-symbol-{32,60,120,144,180,512}.png: seal on a round night-black ground; sizes up to 120 px use the
   simplified small version (ring only, higher contrast, head larger), the large version stays unchanged
 - godot/assets/app/splash-grimmhain.png (boot splash and web loading page): dark backdrop, seal small above the wordmark
Run from the repo root: python tools/build_brand_assets.py [--preview]"""
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

SRC = "C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/marke/"
BRAND = "godot/assets/brand/"
APP = "godot/assets/app/"
NIGHT_BLACK = (5, 7, 13)
SPLASH_BG = (6, 8, 16)


def crop_alpha(img: Image.Image, pad: int = 8) -> Image.Image:
	box = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
	return img.crop((max(box[0] - pad, 0), max(box[1] - pad, 0), min(box[2] + pad, img.width), min(box[3] + pad, img.height)))


def ground(size: int) -> Image.Image:
	"""Opaque square (the OS rounds the corners) with a round, slightly bluer night-black disc."""
	img = Image.new("RGB", (size, size), NIGHT_BLACK)
	yy, xx = np.mgrid[0:size, 0:size]
	d = np.sqrt((xx - size / 2) ** 2 + (yy - size / 2) ** 2) / (size / 2)
	glow = np.clip(1 - d / 0.96, 0, 1)[..., None] ** 1.5
	arr = np.asarray(img).astype(np.float32) + glow * np.array([9, 13, 26], dtype=np.float32)
	return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


def seal_full(seal: Image.Image, size: int) -> Image.Image:
	img = ground(size).convert("RGBA")
	s = round(size * 0.86)
	img.alpha_composite(seal.resize((s, s), Image.LANCZOS), ((size - s) // 2, (size - s) // 2))
	return img.convert("RGB")


def seal_small(seal: Image.Image, size: int) -> Image.Image:
	"""Simplified small version: wolf head enlarged inside a circular mask, fine outer thorns dropped, plain ring, contrast raised."""
	w = seal.width
	head = seal.crop((round(w * 0.1), round(w * 0.1), round(w * 0.9), round(w * 0.9))).convert("RGBA")
	head = ImageEnhance.Brightness(ImageEnhance.Contrast(head).enhance(1.35)).enhance(1.25)
	k = size * 4
	mask = Image.new("L", (k, k), 0)
	ImageDraw.Draw(mask).ellipse((0, 0, k - 1, k - 1), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(k * 0.01)).resize((round(size * 0.84), round(size * 0.84)), Image.LANCZOS)
	s = mask.width
	head = head.resize((s, s), Image.LANCZOS)
	head.putalpha(Image.composite(head.getchannel("A"), Image.new("L", (s, s), 0), mask))
	img = ground(size).convert("RGBA")
	ring = Image.new("RGBA", (k, k), (0, 0, 0, 0))
	r = k * 0.462
	ImageDraw.Draw(ring).ellipse((k / 2 - r, k / 2 - r, k / 2 + r, k / 2 + r), outline=(197, 205, 219, 255), width=max(round(k * 0.03), 4))
	img.alpha_composite(ring.resize((size, size), Image.LANCZOS))
	img.alpha_composite(head, ((size - s) // 2, (size - s) // 2))
	return img.convert("RGB")


def splash(word: Image.Image, seal: Image.Image) -> Image.Image:
	W, H = 1536, 1152
	img = Image.new("RGB", (W, H), SPLASH_BG)
	yy, xx = np.mgrid[0:H, 0:W]
	d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H * 0.5) / (H / 2)) ** 2)
	arr = np.asarray(img).astype(np.float32) + (np.clip(1 - d, 0, 1)[..., None] ** 1.6) * np.array([6, 9, 20], dtype=np.float32)
	img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("RGBA")
	ww = 960
	word = word.resize((ww, round(word.height * ww / word.width)), Image.LANCZOS)
	ss = 230
	seal = seal.resize((ss, ss), Image.LANCZOS)
	gap = 28
	top = (H - (ss + gap + word.height)) // 2 - 30
	img.alpha_composite(seal, ((W - ss) // 2, top))
	img.alpha_composite(word, ((W - ww) // 2, top + ss + gap))
	return img.convert("RGB")


if __name__ == "__main__":
	word = crop_alpha(Image.open(SRC + "wortmarke.png").convert("RGBA"))
	seal = crop_alpha(Image.open(SRC + "siegel.png").convert("RGBA"), 0)
	side = max(seal.size)
	sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	sq.paste(seal, ((side - seal.width) // 2, (side - seal.height) // 2))
	seal = sq
	w16 = word.resize((1600, round(word.height * 1600 / word.width)), Image.LANCZOS)
	w16.save(BRAND + "wortmarke.webp", quality=92, alpha_quality=100, method=6)
	seal.resize((512, 512), Image.LANCZOS).save(BRAND + "siegel.webp", quality=92, alpha_quality=100, method=6)
	for size in (32, 60, 120, 144, 180, 512):
		(seal_small if size <= 120 else seal_full)(seal, size).save(APP + f"app-symbol-{size}.png", optimize=True)
	splash(word, seal).save(APP + "splash-grimmhain.png", optimize=True)
	print("ok", word.size, seal.size)
