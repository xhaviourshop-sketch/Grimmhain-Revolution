"""Builds the painted UI skin (Feedback 8) from Markus' sources in C:/Users/Marku/Downloads/Grimmhain/Assets/ into
godot/assets/ui/skin/, the start media and the role card pictures. Originals stay untouched in Downloads.

Buttons: the three states (knopf, knopf-gedrueckt, knopf-aktiv) are drawn differently (bar thickness, end length).
They are normalized to one canvas (CANVAS_H high, bar BAR_H high and centred) with equally wide ends (CAP_W), so a
3-slice draw (ends scaled with the height, middle stretched) never jumps between states. The red centre stone is
removed from the bar and kept as its own small picture per state (stein_*.webp) for main buttons.
Run from the repo root: python tools/build_ui_skin.py"""
import os
import re
import subprocess

import numpy as np
from PIL import Image

SRC = "C:/Users/Marku/Downloads/Grimmhain/Assets/"
OUT = "godot/assets/ui/skin/"
NIGHT_SCALE = 0.5
CANVAS_H, BAR_H, CAP_W, MID_W, FEATHER = 128, 72, 96, 128, 24

# bar rows (alpha > 200), end of left cap, start of right cap, plain strip, stone centre (source pixels)
BUTTONS = {
	"knopf": dict(bar=(218, 503), cl=360, cr=1812, strip=(500, 900), stone=1086, stone_w=220),
	"knopf-gedrueckt": dict(bar=(30, 129), cl=200, cr=1000, strip=(300, 520), stone=600, stone_w=124),
	"knopf-aktiv": dict(bar=(63, 138), cl=210, cr=992, strip=(300, 520), stone=601, stone_w=124),
}
STATE = {"knopf": "normal", "knopf-gedrueckt": "gedrueckt", "knopf-aktiv": "aktiv"}


def arr(img: Image.Image) -> np.ndarray:
	return np.asarray(img.convert("RGBA")).astype(np.float32)


def save(a, name: str, lossless: bool = False) -> None:
	img = a if isinstance(a, Image.Image) else Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
	img.save(OUT + name, quality=92, alpha_quality=100, method=6, lossless=lossless)


def button(name: str) -> None:
	c = BUTTONS[name]
	im = Image.open(SRC + "ui/" + name + ".png").convert("RGBA")
	w = im.size[0]
	s = BAR_H / (c["bar"][1] - c["bar"][0] + 1)
	cy = (c["bar"][0] + c["bar"][1]) / 2
	y0, y1 = int(round(cy - CANVAS_H / 2 / s)), int(round(cy + CANVAS_H / 2 / s))
	left = arr(im.crop((0, y0, c["cl"], y1)).resize((CAP_W, CANVAS_H), Image.LANCZOS))
	right = arr(im.crop((c["cr"], y0, w, y1)).resize((CAP_W, CANVAS_H), Image.LANCZOS))
	strip = im.crop((c["strip"][0], y0, c["strip"][1], y1))
	mid = arr(strip.resize((MID_W, CANVAS_H), Image.LANCZOS))
	# joins: inside the bar rows the inner FEATHER px of each end cross-fade into the middle's edge column, so the
	# bar has no hard edge where it meets the end; spikes above and below the bar stay as drawn
	out = np.concatenate([left, mid, right], axis=1)
	rows = np.zeros((CANVAS_H, 1, 1), np.float32)
	rows[CANVAS_H // 2 - BAR_H // 2 + 6:CANVAS_H // 2 + BAR_H // 2 - 6] = 1.0
	t = np.linspace(0, 1, FEATHER)[None, :, None]
	lj = slice(CAP_W - FEATHER, CAP_W)
	rj = slice(CAP_W + MID_W, CAP_W + MID_W + FEATHER)
	blend_l = left[:, -FEATHER:] * (1 - t) + mid[:, :1] * t
	blend_r = mid[:, -1:] * (1 - t) + right[:, :FEATHER] * t
	out[:, lj] = out[:, lj] * (1 - rows) + blend_l * rows
	out[:, rj] = out[:, rj] * (1 - rows) + blend_r * rows
	save(out, "knopf_%s.webp" % STATE[name])
	# stone: cut from the bar centre, background (plain bar left and right of it) removed by colour difference
	sw = c["stone_w"]
	x0 = c["stone"] - sw // 2
	region = arr(im.crop((x0, y0, x0 + sw, y1)))
	# the stone is a diamond with a silver rim: a feathered diamond mask isolates it from the bar behind it
	h, wd = region.shape[:2]
	yy, xx = np.mgrid[0:h, 0:wd].astype(np.float32)
	d = np.abs(xx - wd / 2) / (wd / 2) + np.abs(yy - (cy - y0)) / (h / 2)
	region[..., 3] *= np.clip((1.0 - d) / 0.08, 0, 1)
	stone = Image.fromarray(np.clip(region, 0, 255).astype(np.uint8), "RGBA")
	bbox = stone.getbbox()
	stone = stone.crop(bbox)
	stone = stone.resize((max(1, int(stone.size[0] * s)), max(1, int(stone.size[1] * s))), Image.LANCZOS)
	save(stone, "stein_%s.webp" % STATE[name])


def list_row() -> None:
	im = Image.open(SRC + "ui/listenzeile.png").convert("RGBA").crop((0, 38, 1600, 96))
	bbox = im.getbbox()
	im = im.crop((bbox[0], 0, bbox[2], im.size[1]))
	a = arr(im)
	cap = 48
	mid = a[:, 600:856]
	out = np.concatenate([a[:, :cap], mid, a[:, -cap:]], axis=1)
	save(out, "listenzeile.webp")
	print("listenzeile", out.shape, "ends", cap)


def switches() -> None:
	ims = {n: Image.open(SRC + "ui/schalter-%s.png" % n).convert("RGBA") for n in ("an", "aus")}
	boxes = [im.getbbox() for im in ims.values()]
	box = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
	for n, im in ims.items():
		save(im.crop(box), "schalter_%s.webp" % n)
	print("schalter", box[2] - box[0], box[3] - box[1])


def frame() -> None:
	im = Image.open(SRC + "ui/rahmen.png").convert("RGBA")
	im = im.crop(im.getbbox())
	im = im.resize((im.size[0] // 2, im.size[1] // 2), Image.LANCZOS)
	save(im, "rahmen.webp")
	a = np.asarray(im)[..., 3]
	# corner ornament size: first column/row from the corner where the thin edge line starts (alpha only in a narrow band)
	print("rahmen", im.size)


def board() -> None:
	"""Window ground: the source is mirrored four ways (visible cross seam). Take one quadrant, make it seamless
	by cross-fading its wrap-around edges, so the tile repeats without mirror lines."""
	im = Image.open(SRC + "ui/tafel-grund.png").convert("RGB")
	q = arr(im.crop((40, 40, 472, 472)))[..., :3]
	n = q.shape[0]
	o = 96
	t = np.linspace(0, 1, o)
	core = q[:, : n - o]
	core[:, :o] = q[:, n - o:] * (1 - t)[None, :, None] + core[:, :o] * t[None, :, None]
	q2 = core
	core2 = q2[: n - o]
	core2[:o] = q2[n - o:] * (1 - t)[:, None, None] + core2[:o] * t[:, None, None]
	tile = Image.fromarray(np.clip(core2, 0, 255).astype(np.uint8), "RGB").resize((256, 256), Image.LANCZOS)
	tile.save(OUT + "tafel_grund.webp", quality=88, method=6)
	print("tafel", tile.size)


def bonds() -> None:
	for n in ("liebende", "rivalen"):
		im = Image.open(SRC + "ui/bund-%s.png" % n).convert("RGBA")
		im = im.crop(im.getbbox())
		im.thumbnail((512, 512), Image.LANCZOS)
		save(im, "bund_%s.webp" % n)


def bar_crop(name: str, scale: float) -> Image.Image:
	im = Image.open(SRC + "ui/%s.png" % name).convert("RGBA")
	im = im.crop(im.getbbox())
	return im.resize((max(1, round(im.size[0] * scale)), max(1, round(im.size[1] * scale))), Image.LANCZOS)


def ui_parts() -> None:
	"""Feedback 9 parts: input field, plaque, divider, side tab, night bar (+ separate clasp), edge knob, die face,
	seat frame and the small bond marks. Scales keep every part at most twice its display size."""
	for name, scale, out in (("eingabefeld", 0.75, "eingabefeld"), ("plakette", 0.5, "plakette"),
			("trennlinie", 0.4, "trennlinie"), ("randlasche", 0.4, "randlasche")):
		im = bar_crop(name, scale)
		save(im, out + ".webp")
		print(out, im.size)
	# night bar: the centre clasp is cut out and kept as its own picture, so the stretched middle never distorts it
	src = Image.open(SRC + "ui/nachtleiste.png").convert("RGBA")
	a = arr(src)
	box = src.getbbox()
	cx0, cx1 = 925, 1060                       # clasp columns (source pixels), clasp rows 313..462, bar rows 371..413
	mid = (371 + 413) // 2                     # bar centre row: crops are symmetric around it so the bar sits in the picture middle
	half = max(mid - box[1], box[3] - mid)
	clasp = Image.fromarray(a[mid - 79:mid + 80, cx0:cx1].astype(np.uint8), "RGBA")
	plain = a.copy()
	plain[:, cx0:cx1] = a[:, cx0 - (cx1 - cx0):cx0]  # plain bar from the left of the clasp
	bar = Image.fromarray(plain.astype(np.uint8), "RGBA").crop((box[0], mid - half, box[2], mid + half))
	for im, out in ((bar, "nachtleiste"), (clasp, "nachtleiste_spange")):
		scaled = im.resize((round(im.size[0] * NIGHT_SCALE), round(im.size[1] * NIGHT_SCALE)), Image.LANCZOS)
		save(scaled, out + ".webp")
		print(out, scaled.size)
	for name, size, out in (("randknopf", 160, "randknopf"), ("sitzrahmen", 256, "sitzrahmen"), ("wuerfel", 256, "wuerfel"),
			("bund-liebende-klein", 128, "bund_liebende_klein"), ("bund-rivalen-klein", 128, "bund_rivalen_klein")):
		im = Image.open(SRC + "ui/%s.png" % name).convert("RGBA").resize((size, size), Image.LANCZOS)
		save(im, out + ".webp")
	# seat frame hole: circle fitted to the inner edge, measured on the finished picture (fractions of the width)
	f = np.asarray(Image.open(OUT + "sitzrahmen.webp").convert("RGBA"))[..., 3] > 40
	h, w = f.shape
	yy, xx = np.mgrid[0:h, 0:w]
	cy, cx = yy[f].mean(), xx[f].mean()
	m = f & (np.hypot(xx - cx, yy - cy) < w * 0.36)
	X, Y = xx[m], yy[m]
	sol = np.linalg.lstsq(np.c_[2 * X, 2 * Y, np.ones(len(X))], X ** 2 + Y ** 2, rcond=None)[0]
	hx, hy = sol[0], sol[1]
	d = np.hypot(xx[f] - hx, yy[f] - hy)
	print("sitzrahmen hole centre %.4f %.4f  clear radius %.4f  1st percentile %.4f" % (hx / w, hy / h, d.min() / w, np.percentile(d, 1) / w))


def start_media() -> None:
	im = Image.open(SRC + "start/ladebild.png").convert("RGB")
	im.save("godot/web/ladebild.webp", quality=85, method=6)
	ff = "ffmpeg"
	os.makedirs("godot/assets/audio", exist_ok=True)
	subprocess.run([ff, "-y", "-loglevel", "error", "-i", SRC + "start/musik-start.mp3", "-ac", "2", "-ar", "44100",
		"-c:a", "libvorbis", "-q:a", "3", "godot/assets/audio/musik-start.ogg"], check=True)
	subprocess.run([ff, "-y", "-loglevel", "error", "-i", SRC + "audio/musik-nacht.mp3", "-ac", "2", "-ar", "44100",
		"-c:a", "libvorbis", "-q:a", "3", "godot/assets/audio/musik-nacht.ogg"], check=True)
	os.makedirs("godot/assets/audio/heulen", exist_ok=True)
	for name in ("heulen-1", "heulen-2-fern", "heulen-3"):
		subprocess.run([ff, "-y", "-loglevel", "error", "-i", SRC + "audio/heulen/" + name + ".mp3", "-ac", "2", "-ar", "44100",
			"-c:a", "libvorbis", "-q:a", "3", "godot/assets/audio/heulen/" + name + ".ogg"], check=True)


CARD_EN_EXCEPTIONS = {"doppelspion": "Doppelspion.webp", "kartenschlucker": "The_Collector.webp",
	"rachsuechtiger_wolf": "Vengeful_Wolf.webp"}


def cards() -> None:
	"""Role card pictures (Markus' own card game, released): named by role id, 1024 px high, WebP q80."""
	def names(lang):
		t = open("godot/content/i18n/ui.%s.po" % lang, encoding="utf-8").read()
		return dict(re.findall(r'msgid "ui\.role\.([a-z0-9_]+)\.name"\r?\nmsgstr "([^"]*)"', t))

	def norm(s):
		return re.sub(r"[^a-z0-9äöüß]", "", s.lower())

	for lang in ("de", "en"):
		src = "assets/cards/%s/" % lang
		files = {norm(re.sub(r"_(DE|EN)$", "", f[:-5])): f for f in os.listdir(src)}
		out = "godot/assets/cards/%s/" % lang
		os.makedirs(out, exist_ok=True)
		for rid, name in names(lang).items():
			f = CARD_EN_EXCEPTIONS.get(rid) if lang == "en" and rid in CARD_EN_EXCEPTIONS else files[norm(name)]
			im = Image.open(src + f).convert("RGB")
			im = im.resize((int(im.size[0] * 1024 / im.size[1]), 1024), Image.LANCZOS)
			im.save(out + rid + ".webp", quality=80, method=6)
		print("cards", lang, len(os.listdir(out)))


if __name__ == "__main__":
	os.makedirs(OUT, exist_ok=True)
	for b in BUTTONS:
		button(b)
	list_row()
	switches()
	frame()
	board()
	bonds()
	ui_parts()
	start_media()
	cards()
	print("ok")
