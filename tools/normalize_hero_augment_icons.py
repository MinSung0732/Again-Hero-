"""Offline extraction of the irregular generated sheets; Pillow + numpy only.

Opaque connected cores protect complete symbols crossing nominal cell edges.
Translucent glow pixels are assigned to the nearest symbol, then each symbol
is fitted/centered with nearest filtering in a padded 128px runtime cell.
Original generated sheets are never overwritten.
"""
from collections import deque
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/art/ui/hero_augments"
CELL, INSET = 128, 10


def normalize(source, columns, rows, centers_y):
    rgba = np.array(Image.open(ART / source).convert("RGBA"))
    height, width = rgba.shape[:2]
    core = rgba[:, :, 3] >= 128
    labels = np.full((height, width), -1, dtype=np.int16)
    centers_x = [width * (col + 0.5) / columns for col in range(columns)]
    cores = [[] for _ in range(columns * rows)]
    # Flood fill is offline only. No image scans or normalization in game.
    for y, x in zip(*np.where(core)):
        if not core[y, x]:
            continue
        points = [(int(x), int(y))]
        core[y, x] = False
        for px, py in points:
            for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                if 0 <= nx < width and 0 <= ny < height and core[ny, nx]:
                    core[ny, nx] = False
                    points.append((nx, ny))
        if len(points) < 3000:
            continue
        cx, cy = np.mean(points, axis=0)
        col = min(range(columns), key=lambda index: abs(centers_x[index] - cx))
        row = min(range(rows), key=lambda index: abs(centers_y[index] - cy))
        cores[row * columns + col].extend(points)
    assert all(cores), f"Missing symbol core: {source}"
    queue = deque()
    for index, points in enumerate(cores):
        for x, y in points:
            labels[y, x] = index
            queue.append((x, y, 0))
    # Grow up to 24px around each protected core, including disconnected sparkles.
    while queue:
        x, y, distance = queue.popleft()
        if distance >= 24:
            continue
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and labels[ny, nx] < 0:
                labels[ny, nx] = labels[y, x]
                queue.append((nx, ny, distance + 1))
    atlas = Image.new("RGBA", (columns * CELL, rows * CELL))
    regions = []
    for index in range(columns * rows):
        mask = (labels == index) & (rgba[:, :, 3] >= 12)
        ys, xs = np.where(mask)
        box = [int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)]
        isolated = rgba[box[1]:box[3], box[0]:box[2]].copy()
        isolated[~mask[box[1]:box[3], box[0]:box[2]]] = 0
        icon = Image.fromarray(isolated)
        scale = (CELL - INSET * 2) / max(icon.size)
        icon = icon.resize(tuple(max(1, round(v * scale)) for v in icon.size), Image.Resampling.NEAREST)
        # Nearest downsampling can remove a one-pixel spark on one edge.
        icon = icon.crop(icon.getbbox())
        column, row = index % columns, index // columns
        atlas.paste(icon, (column * CELL + (CELL - icon.width) // 2, row * CELL + (CELL - icon.height) // 2))
        regions.append(box)
    target = source.replace(".png", "_normalized.png")
    atlas.save(ART / target)
    return atlas, regions, target


def main():
    manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
    results = {}
    for source, columns, rows, centers in [
        ("weapons.png", 6, 10, [95, 250, 400, 550, 705, 865, 1025, 1190, 1350, 1505]),
        ("passives.png", 4, 2, [225, 650]),
    ]:
        atlas, bounds, target = normalize(source, columns, rows, centers)
        results[source] = (bounds, target, columns)
    counts = {key: 0 for key in results}
    for record in manifest["icons"].values():
        source = record.get("source_sheet", record["sheet"])
        bounds, target, columns = results[source]
        index = counts[source]
        record.update(source_sheet=source, source_bounds=bounds[index], sheet=target,
                      region=[index % columns * CELL, index // columns * CELL, CELL, CELL])
        counts[source] += 1
    manifest["normalization"] = {"cell": CELL, "minimum_padding": INSET, "tool": "tools/normalize_hero_augment_icons.py"}
    (ART / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Normalized", counts)


if __name__ == "__main__":
    main()
