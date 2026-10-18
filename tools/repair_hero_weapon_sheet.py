"""Split reviewed source anchors without cutting components at nominal grid lines.

Offline only. Uses existing alpha, never a colour key. Every opaque source pixel
is assigned once to a frame; a connected component cannot straddle two frames.
Run: python tools/repair_hero_weapon_sheet.py docs/HERO_WEAPON_ART_REPAIR_LAYOUT_20261014.json
"""
from pathlib import Path
import hashlib
import json
import math
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

repo = Path(__file__).resolve().parents[1]
layout = json.loads(Path(sys.argv[1]).read_text())
for weapon_id, spec in layout.items():
    folder = repo / 'assets/art/effects/hero_weapon_v2' / weapon_id
    source = folder / 'source.png'
    image = Image.open(source).convert('RGBA')
    pixels = np.array(image)
    opaque = pixels[:, :, 3] >= 128
    labels, count = ndimage.label(opaque, structure=np.ones((3, 3)))
    centers = np.array(ndimage.center_of_mass(opaque, labels, range(1, count + 1)))[:, ::-1]
    anchors = np.array(spec['source_anchors'])
    owners = np.argmin(((centers[:, None] - anchors[None]) ** 2).sum(axis=2), axis=1)
    lookup = np.zeros(count + 1, dtype=np.uint8)
    lookup[1:] = owners + 1
    assignment = lookup[labels]
    masks = [assignment == i + 1 for i in range(9)]
    assert sum(int(mask.sum()) for mask in masks) == int(opaque.sum())
    bounds = []
    for mask in masks:
        ys, xs = np.where(mask)
        assert len(xs)
        bounds.append([int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1])
    extent = math.ceil(max(max(abs(b[0] - a[0]), abs(b[2] - a[0]),
                               abs(b[1] - a[1]), abs(b[3] - a[1]))
                           for b, a in zip(bounds[1:], anchors[1:]))) + 2
    sheet = Image.open(folder / 'sprite_sheet.png').convert('RGBA')
    hashes = []
    for i, (mask, anchor) in enumerate(zip(masks[1:], anchors[1:]), 1):
        isolated = pixels.copy()
        isolated[~mask] = 0
        isolated[mask, 3] = 255
        frame = Image.fromarray(isolated).crop((int(anchor[0]) - extent, int(anchor[1]) - extent,
                                               int(anchor[0]) + extent, int(anchor[1]) + extent))
        logical = frame.resize((56, 56), Image.Resampling.NEAREST)
        final = Image.new('RGBA', (128, 128))
        final.paste(logical.resize((112, 112), Image.Resampling.NEAREST), (8, 8))
        box = final.getchannel('A').getbbox()
        assert box and min(box[:2]) >= 8 and max(box[2:]) <= 120
        final.save(folder / 'frames' / f'effect_{i:02d}.png')
        sheet.paste(final, (i % 3 * 128, i // 3 * 128))
        hashes.append(hashlib.sha256(final.tobytes()).hexdigest())
    sheet.save(folder / 'sprite_sheet.png')
    manifest_path = folder / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    manifest.update(source_size=list(image.size), source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                    source_file='source.png', source_anchors=spec['source_anchors'][1:],
                    source_component_bounds=bounds[1:], common_source_extent=extent,
                    source_opaque_pixels=int(opaque.sum()), assigned_opaque_pixels=sum(int(m.sum()) for m in masks),
                    normalization='whole alpha components; reviewed core anchors; one common nearest scale; no source crop loss',
                    unique_frames=len(set(hashes)))
    manifest.pop('common_source_crop', None)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(weapon_id, 'frames=8', 'source_pixels_assigned_once=' + str(opaque.sum()))
