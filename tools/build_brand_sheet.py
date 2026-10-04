"""Contact sheet for the brand (app symbol sizes, loading screen, start screen, main menu at 1024x768).
Usage: python tools/build_brand_sheet.py <start-1024x768.png> <menue-1024x768.png> <out.png>"""
import sys
from PIL import Image, ImageDraw

start, menu, out = sys.argv[1:4]
splash = Image.open("godot/assets/app/splash-grimmhain.png").convert("RGB").resize((1024, 768), Image.LANCZOS)
shots = [("Ladebildschirm", splash), ("Startbildschirm", Image.open(start).convert("RGB")), ("Hauptmenue", Image.open(menu).convert("RGB"))]
sizes = (32, 60, 120, 144, 180, 512)
W = 3 * 1024 + 4 * 24
sheet = Image.new("RGB", (W, 40 + 512 + 60 + 40 + 768 + 24), (30, 32, 40))
d = ImageDraw.Draw(sheet)
d.text((24, 12), "App-Symbol (1:1, Pixelgroesse unter dem Symbol)", fill=(200, 205, 215))
x = 24
for s in sizes:
	sheet.paste(Image.open(f"godot/assets/app/app-symbol-{s}.png").convert("RGB"), (x, 40))
	d.text((x, 40 + 512 + 6), f"{s} px", fill=(200, 205, 215))
	x += s + 24
y = 40 + 512 + 60
for i, (label, img) in enumerate(shots):
	d.text((24 + i * (1024 + 24), y), label + " 1024x768", fill=(200, 205, 215))
	sheet.paste(img, (24 + i * (1024 + 24), y + 20))
sheet.save(out, optimize=True)
print("ok", sheet.size)
