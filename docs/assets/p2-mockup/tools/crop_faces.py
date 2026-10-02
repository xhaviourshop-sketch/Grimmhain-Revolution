import cv2, os, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

D = r"C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/"
SC = r"C:/Users/Marku/AppData/Local/Temp/claude/C--Users-Marku-Desktop-Grimmhain-Grimmhain---Revolution/0dbb4350-77d8-481f-8ba2-e35a00044365/scratchpad/"
OUT = SC + "cand/"
os.makedirs(OUT, exist_ok=True)
sheets = {"A": ("G2A-portraits-v1.png", 3, 2), "B": ("G2B-portraits-v1.png", 3, 2),
          "C": ("P2-01-portraits-C-v1.png", 4, 2), "D": ("P2-02-portraits-D-v1.png", 4, 2)}
BG = (20, 22, 29)
cas = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
meta = []
for k, (f, cols, rows) in sheets.items():
    pil = Image.open(D + f).convert("RGB")
    im = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
    h, w = im.shape[:2]
    cw, ch = w // cols, h // rows
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * cw, r * ch
            cell = im[y0:y0 + ch, x0:x0 + cw]
            g = cv2.equalizeHist(cv2.cvtColor(cell, cv2.COLOR_BGR2GRAY))
            fs = sorted(cas.detectMultiScale(g, 1.1, 6, minSize=(100, 100)), key=lambda x: -x[2])
            fx, fy, fw, fh = [int(v) for v in fs[0]]
            cx = x0 + fx + fw / 2
            cy = y0 + fy + fh / 2 - 0.10 * fw
            S = 1.75 * fw
            box = (int(cx - S / 2), int(cy - S / 2), int(cx + S / 2), int(cy + S / 2))
            # keep the crop inside the cell columns, shift when needed
            dx = max(0, x0 - box[0]) - max(0, box[2] - (x0 + cw))
            dy = max(0, y0 - box[1]) - max(0, box[3] - (y0 + ch))
            box = (box[0] + dx, box[1] + dy, box[2] + dx, box[3] + dy)
            crop = pil.crop(box).resize((256, 256), Image.LANCZOS)
            name = "%s%d" % (k, r * cols + c + 1)
            crop.save(OUT + name + ".png")
            meta.append({"id": name, "sheet": k, "cell": r * cols + c + 1, "face": [fx, fy, fw, fh], "box": list(box)})
json.dump(meta, open(OUT + "meta.json", "w"), indent=1)
ids = [m["id"] for m in meta]
cols = 9
rows = (len(ids) + cols - 1) // cols
T = 256
sheet = Image.new("RGB", (cols * T, rows * T), BG)
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype("arial.ttf", 30)
for i, n in enumerate(ids):
    sheet.paste(Image.open(OUT + n + ".png"), ((i % cols) * T, (i // cols) * T))
    d.text(((i % cols) * T + 8, (i // cols) * T + 4), n, fill=(255, 255, 0), font=font, stroke_width=2, stroke_fill=(0, 0, 0))
sheet.save(SC + "cand_sheet.png")
print(len(ids), "ok")
