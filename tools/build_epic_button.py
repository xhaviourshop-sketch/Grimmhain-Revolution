"""Cuts Markus' epic button image (C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/ui/start-knopf.png, 2172x724) into
godot/assets/ui/epic_button_{left,mid,right}.webp: left end (wolf), tileable lava middle, right end (claw marks).
Ends are never stretched; the middle repeats. The middle is cross-faded at its seam so it tiles without an edge; the inner
edge of each end fades to transparent so it blends over the middle tile (the middle is drawn underneath, across the join).
Run from the repo root: python tools/build_epic_button.py"""
import numpy as np
from PIL import Image

SRC = "C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/ui/start-knopf.png"
OUT = "godot/assets/ui/epic_button_"
Y0, Y1 = 112, 587          # full ornament height (spikes included); the bars span y 185..508
LEFT_END, MID_END = 600, 1640
RIGHT_START, RIGHT_END = 1640, 2151
LEFT_START = 22
FEATHER = 60
OVERLAP = 140

img = Image.open(SRC).convert("RGBA").crop((0, Y0, 2172, Y1))
arr = np.asarray(img).astype(np.float32)


def save(a: np.ndarray, name: str) -> None:
	Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").save(OUT + name + ".webp", quality=92, alpha_quality=100, method=6)


left = arr[:, LEFT_START:LEFT_END].copy()
left[:, -FEATHER:, 3] *= np.linspace(1, 0, FEATHER)[None, :]
right = arr[:, RIGHT_START:RIGHT_END].copy()
right[:, :FEATHER, 3] *= np.linspace(0, 1, FEATHER)[None, :]
mid = arr[:, LEFT_END:MID_END].copy()
w = mid.shape[1]
t = np.linspace(0, 1, OVERLAP)[None, :, None]
head = mid[:, w - OVERLAP:] * (1 - t) + mid[:, :OVERLAP] * t
mid = np.concatenate([head, mid[:, OVERLAP:w - OVERLAP]], axis=1)
save(left, "left")
save(mid, "mid")
save(right, "right")
print("ok", left.shape, mid.shape, right.shape)
