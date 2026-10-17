"""Package imagegen's 2x2 flight loops at native pixel resolution, never resample."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/art/projectiles/frontier'


def package(row):
    species = row['id']
    folder = BASE / species
    frames = folder / 'frames'
    frames.mkdir(parents=True, exist_ok=True)
    source = Path(row['source'])
    original = folder / f'{species}_source.png'
    if not source.is_file():
        source = original  # A fresh clone can rebuild from the preserved original.
    if source.resolve() != original.resolve():
        shutil.copyfile(source, original)
    image = Image.open(original).convert('RGBA')
    width, height = image.size
    assert width % 2 == 0 and height % 2 == 0
    source_cell = (width // 2, height // 2)
    rgba = np.array(image)
    # Generated soft alpha is cleaned at its boundary; retained RGB stays 1:1.
    rgba[:, :, 3] = np.where(rgba[:, :, 3] >= 128, 255, 0)
    rgba[rgba[:, :, 3] == 0, :3] = 0
    source_sheet = Image.fromarray(rgba)
    samples = []
    anchors = []
    half_w = half_h = 0
    for i in range(4):
        x,y = (i%2)*source_cell[0], (i//2)*source_cell[1]
        sample = source_sheet.crop((x,y,x+source_cell[0],y+source_cell[1]))
        mask = np.array(sample)[:,:,3] != 0
        labels,count = ndimage.label(mask)
        sizes = np.bincount(labels.ravel()); sizes[0] = 0
        ys,xs = np.where(labels == sizes.argmax())
        # The rigid leading body supplies a stable anchor; tail/floating flecks
        # cannot pull the center around. Integer translation preserves RGB pixels.
        head = xs >= xs.max()-(xs.max()-xs.min())*.3
        anchor = (int(xs.max()-(xs.max()-xs.min())*.15),int(round(ys[head].mean())))
        box = sample.getbbox()
        half_w = max(half_w,anchor[0]-box[0],box[2]-anchor[0])
        half_h = max(half_h,anchor[1]-box[1],box[3]-anchor[1])
        anchors.append(anchor); samples.append(sample)
    cell = (2*(half_w+16),2*(half_h+16))
    sheet = Image.new('RGBA',(cell[0]*2,cell[1]*2))
    boxes = []
    files = []
    for i in range(4):
        x, y = (i % 2) * cell[0], (i // 2) * cell[1]
        frame = Image.new('RGBA',cell)
        shift = (cell[0]//2-anchors[i][0],cell[1]//2-anchors[i][1])
        frame.paste(samples[i],shift)
        box = frame.getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < cell[0] and box[3] < cell[1], (species, i, box)
        boxes.append(box)
        filename = f'frames/projectile_{i+1:02d}.png'
        frame.save(folder / filename)
        sheet.paste(frame,(x,y))
        files.append(filename)
    sheet.save(folder / f'{species}_spritesheet.png')
    # One scale for the entire loop; never stretch individual frames to their bounds.
    extent = max(max(abs(b[0]-cell[0]/2), abs(b[2]-cell[0]/2)) for b in boxes)*2
    scale = round(48.0 / extent, 8)
    manifest = dict(species_id=species, direction='right', cell_size=cell,
                    sheet_size=sheet.size, source_cell_size=source_cell, source_anchors=anchors,
                    layout=[2, 2], anchor=[cell[0]/2, cell[1]/2],
                    source_file=original.name, source_sha256=hashlib.sha256(original.read_bytes()).hexdigest(),
                    packaging='Native 1:1 crop and integer core-anchor alignment; alpha>=128 boundary cleanup; no RGB keying or resampling',
                    bounds=boxes, display_scale=scale, animations={'projectile':dict(fps=12, loop=True, frames=files)},
                    generation=row)
    (folder / 'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    (folder / 'README.md').write_text(f'''# {species} projectile

- Generated with built-in imagegen using this monster's existing art as palette/material reference.
- `{species}_source.png`: unmodified generated original.
- `{species}_spritesheet.png`: 2x2 flight loop; 4 individual PNGs in `frames/`.
- `{species}_animations.tres`: Godot SpriteFrames, projectile / 12fps / loop.
- `manifest.json`: exact prompt, provenance, native crop/anchor coordinates and shared display scale.
- Native RGB pixels preserved; alpha>=128 boundary cleanup and integer alignment only. No resizing, color-keying or palette compression.
- Both normal and elite attacks use this species profile through FrontierProjectileArtCatalog.
''')
    resources = '\n'.join(f'[ext_resource type="Texture2D" path="res://assets/art/projectiles/frontier/{species}/{name}" id="{i+1}"]' for i,name in enumerate(files))
    sequence = ',\n'.join('{"duration": 1.0, "texture": ExtResource("%d")}'%(i+1) for i in range(4))
    (folder / f'{species}_animations.tres').write_text(f'''[gd_resource type="SpriteFrames" load_steps=5 format=3]
{resources}
[resource]
animations = [{{"frames": [{sequence}], "loop": true, "name": &"projectile", "speed": 12.0}}]
''')
    return scale


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('prompt_manifest', type=Path)
    args = parser.parse_args()
    rows = json.loads(args.prompt_manifest.read_text())
    profiles = []
    for row in rows:
        scale = package(row)
        species = row['id']
        profiles.append(f'\t"{species}": {{"frames": preload("res://assets/art/projectiles/frontier/{species}/{species}_animations.tres"), "scale": {scale}}}')
    (ROOT / 'src/data/frontier_projectile_art_catalog.gd').write_text('extends RefCounted\n## Native-resolution generated flight loops. All resources are shared across pooled bolts.\nconst PROFILES := {\n'+',\n'.join(profiles)+'\n}\n')
    print('Packaged',len(rows),'species /',len(rows)*4,'native flight frames')


if __name__ == '__main__':
    main()
