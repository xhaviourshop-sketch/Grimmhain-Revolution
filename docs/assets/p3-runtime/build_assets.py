"""Builds the runtime assets of the night board (P3) into godot/assets/night/.

Scratch tool, machine dependent: SRC_WK, SRC_DL point to folders on the development machine
(`Grimmhain Assets` and the hand-over folder in Downloads). Run from the repository root:
    python docs/assets/p3-runtime/build_assets.py
All outputs are development material with the register status `intern-freigegeben` (see ../../masterplan/ASSET-REGISTER.md).
"""
import os
import shutil
from PIL import Image

SRC_WK = "C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Werwolf/Grimmhain Assets/"
SRC_DL = "C:/Users/Marku/Downloads/Grimmhain/Archiv/P1-Nachtentwurf/"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
P2 = ROOT + "/docs/assets/p2-mockup/"
P1 = ROOT + "/docs/assets/p1-mockup/"
OUT = ROOT + "/godot/assets/night/"

# role key -> probe-sheet emblem number (P2-04); symbol 6 (wolf with cap) is rejected, wolfskind falls back to the circle image
EMBLEM = {"die-gebundenen": 7, "schutzengel": 2, "werwolf": 1, "rachsuechtiger-wolf": 8, "koenig-lykaon": 5, "waldhexe": 3, "rattenfaenger": 4}
BADGES = {"protected": 1, "poisoned": 2, "marked": 3, "silenced": 4, "dead": 5, "special": 6}
OVERLAYS = {"overlay-active": "ring-active", "overlay-selected": "ring-selected", "overlay-target": "ring-target", "overlay-dead": "ring-dead",
            "overlay-protected": "ring-protected", "ring-marked": "ring-marked", "ring-poisoned": "ring-poisoned", "ring-silenced": "ring-silenced"}


def out(rel):
    path = OUT + rel
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def fit(im, width=None, height=None):
    if width is not None:
        return im.resize((width, max(1, round(im.height * width / im.width))), Image.LANCZOS)
    return im.resize((max(1, round(im.width * height / im.height)), height), Image.LANCZOS)


def trimmed(im):
    box = im.getchannel("A").getbbox()
    return im.crop(box) if box else im


def main():
    # background: G1 as candidate image, lossy WebP
    Image.open(SRC_DL + "G1-village-night-v1.png").convert("RGB").save(out("bg/village-night.webp"), quality=92, method=6)
    # 24 portraits
    for i in range(1, 25):
        Image.open(P2 + "faces/face-%02d.png" % i).convert("RGB").save(out("portraits/face-%02d.webp" % i), quality=92, method=6)
    # seat frame and ring overlays
    fit(Image.open(SRC_WK + "player-frame-neutral.png").convert("RGBA"), 256).save(out("frames/seat-frame.png"), optimize=True)
    for src, name in OVERLAYS.items():
        fit(Image.open(SRC_WK + src + ".png").convert("RGBA"), 256).save(out("frames/%s.png" % name), optimize=True)
    # status badges
    for kind, n in BADGES.items():
        fit(Image.open(P2 + "badges/badge-%02d.png" % n).convert("RGBA"), 96).save(out("badges/badge-%s.png" % kind), optimize=True)
    # role emblems (assigned ones only) and circle images (72)
    for key, n in EMBLEM.items():
        fit(Image.open(P2 + "emblems/emblem-%02d.png" % n).convert("RGBA"), 128).save(out("emblems/%s.png" % key), optimize=True)
    for f in sorted(os.listdir(P2 + "night-icons-circle")):
        key = f[len("night-icon-"):-len(".webp")]
        shutil.copyfile(P2 + "night-icons-circle/" + f, out("role-circle/%s.webp" % key))
    for f in sorted(os.listdir(SRC_WK + "production-pilot/role-art/portraits-512")):
        key = f[len("portrait-"):-len(".webp")]
        shutil.copyfile(SRC_WK + "production-pilot/role-art/portraits-512/" + f, out("role-art/%s.webp" % key))
    # tabs, slots, frames, buttons, plates
    fit(Image.open(P2 + "parts/tab-protocol.png").convert("RGBA"), 96).save(out("ui/tab-protocol.png"), optimize=True)
    fit(Image.open(P2 + "parts/tab-options.png").convert("RGBA"), 96).save(out("ui/tab-options.png"), optimize=True)
    for s in ("active", "done", "inactive"):
        fit(Image.open(P2 + "parts/slot-%s.png" % s).convert("RGBA"), height=256).save(out("ui/slot-%s.png" % s), optimize=True)
    fit(Image.open(P2 + "parts/action-frame-night.png").convert("RGBA"), 330).save(out("ui/role-frame.png"), optimize=True)
    # 1x-Bilder für gestreckte Flächen (9-Slice bzw. ganze Fläche): Ränder werden in Bildpunkten gezeichnet, deshalb in Anzeigegröße
    fit(Image.open(P1 + "echt2/crop-btn-next-step.png").convert("RGBA"), height=64).save(out("ui/btn-next-step.png"), optimize=True)
    fit(Image.open(P1 + "echt2/crop-btn-undo.png").convert("RGBA"), height=48).save(out("ui/btn-undo.png"), optimize=True)
    bar = Image.open(SRC_WK + "nightorder-bar-frame.png").convert("RGBA")
    fit(bar, 887).save(out("ui/bar-frame.png"), optimize=True)
    fit(bar, height=60).save(out("ui/plate-frame.png"), optimize=True)
    for side in ("left", "right"):
        fit(trimmed(Image.open(SRC_WK + "arrow-%s.png" % side).convert("RGBA")), height=96).save(out("ui/arrow-%s.png" % side), optimize=True)
    total = sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(OUT) for f in fs)
    print("ok, %d KB" % (total // 1024))


if __name__ == "__main__":
    main()
