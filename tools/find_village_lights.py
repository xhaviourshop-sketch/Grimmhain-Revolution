"""Find lanterns and lit windows in the village night image.
Usage (run from outside the project): python -I find_village_lights.py <night.png> <overlay.png>
Prints blobs as [x, y, width, height, pixels] in image pixels (1672x941) and writes an overlay.
Sorting into lanterns and windows is done by hand from the overlay (see village_light_spots.gd).
"""
import sys
from collections import deque
from PIL import Image, ImageDraw


def blobs(im, thr):
    w, h = im.size
    px = im.load()
    mask = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y][:3]
            if r > thr and g > thr * 0.55 and b < r * 0.75 and r - b > 70:
                mask[y][x] = True
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            if mask[y][x] and not seen[y][x]:
                q = deque([(x, y)])
                seen[y][x] = True
                pts = []
                while q:
                    cx, cy = q.popleft()
                    pts.append((cx, cy))
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and mask[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            q.append((nx, ny))
                if len(pts) >= 12:
                    xs = [p[0] for p in pts]
                    ys = [p[1] for p in pts]
                    out.append(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, max(xs) - min(xs) + 1, max(ys) - min(ys) + 1, len(pts)))
    return out


def cluster(res, dist=16, min_px=40):
    cl = []
    for cx, cy, _bw, _bh, n in res:
        for c in cl:
            if abs(c[0] / c[2] - cx) < dist and abs(c[1] / c[2] - cy) < dist:
                c[0] += cx * n
                c[1] += cy * n
                c[2] += n
                break
        else:
            cl.append([cx * n, cy * n, n])
    return [(round(c[0] / c[2]), round(c[1] / c[2]), c[2]) for c in cl if c[2] >= min_px]


def main():
    im = Image.open(sys.argv[1]).convert("RGB")
    out = cluster(blobs(im, 225))
    ov = im.copy()
    d = ImageDraw.Draw(ov)
    for i, (x, y, n) in enumerate(out):
        print("%d: [%d, %d, %d]" % (i, x, y, n))
        d.ellipse([x - 12, y - 12, x + 12, y + 12], outline=(0, 255, 0))
        d.text((x + 14, y - 6), str(i), fill=(255, 255, 255))
    ov.save(sys.argv[2])
    w, h = ov.size
    for k, box in enumerate([(0, 0, w // 2, h // 2), (w // 2, 0, w, h // 2), (0, h // 2, w // 2, h), (w // 2, h // 2, w, h)]):
        ov.crop(box).resize((w, h)).save(sys.argv[2].replace(".png", "_q%d.png" % (k + 1)))
    print(len(out), "clusters")


main()
