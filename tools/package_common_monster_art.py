"""Package generated sheets using reviewed crop/anchor records, never RGB keying.

Usage: python tools/package_common_monster_art.py source.json
Input: list of {id,name,form,source,height,design,prompt}; optionally regions.
Build-time only; does not register any monster in the game.
"""
from pathlib import Path
import hashlib
import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
ANIMS = [('idle', 4, 6, True), ('move', 6, 10, True),
         ('attack', 6, 14, False), ('hit', 3, 12, False), ('death', 4, 10, False)]
CELL = (96, 80)
ANCHOR = (48, 68)


def boundaries(projection, count):
    """Find transparent gutters near the expected grid; do not cut occupied pixels."""
    result = [0]
    size = len(projection)
    for index in range(1, count):
        center = size * index / count
        low = max(result[-1] + 1, round(center - size / count * .35))
        high = min(size - 1, round(center + size / count * .35))
        runs = []
        start = None
        for point in range(low, high + 1):
            if projection[point] == 0 and start is None:
                start = point
            if (projection[point] != 0 or point == high) and start is not None:
                end = point if projection[point] else point + 1
                runs.append((start, end))
                start = None
        if not runs:
            raise ValueError(f'No transparent gutter at {index}/{count}; review source')
        # Prefer the widest genuine gap, then its distance to the nominal boundary.
        a, b = max(runs, key=lambda r: (r[1] - r[0], -abs((r[0]+r[1])/2-center)))
        result.append((a+b)//2)
    return result + [size]


def package(record):
    source = Path(record['source'])
    raw = Image.open(source).convert('RGBA')
    pixels = np.array(raw)
    pixels[:, :, 3] = np.where(pixels[:, :, 3] >= 128, 255, 0)
    pixels[pixels[:, :, 3] == 0] = 0
    clean = Image.fromarray(pixels)
    mask = pixels[:, :, 3] > 0
    ys = boundaries(mask.sum(axis=1), 5)
    frames = []
    for row, (anim, count, fps, loop) in enumerate(ANIMS):
        row_pixels = pixels[ys[row]:ys[row+1]].copy()
        isolated = []
        try:
            xs = boundaries(mask[ys[row]:ys[row+1]].sum(axis=0), 6)
        except ValueError:
            # Long tongues/weapon tips may share x ranges without touching in 2D.
            # Isolate complete connected sprites instead of slicing those tips.
            a = row_pixels[:, :, 3] > 0
            labels, total = ndimage.label(ndimage.binary_dilation(a, iterations=2))
            sizes = np.bincount(labels[a])
            major = [i for i in range(1, len(sizes)) if sizes[i] > max(sizes[1:])*.15]
            if len(major) != count:
                raise ValueError(f'{record["id"]}/{anim}: merged or missing sprites; manual review required')
            primary = np.where(np.isin(labels, major), labels, 0)
            nearest = ndimage.distance_transform_edt(primary == 0, return_distances=False, return_indices=True)
            owner = primary[tuple(nearest)]
            assignments = {i: i for i in major}
            for i in range(1, total+1):
                if i not in assignments:
                    choices = owner[(labels == i) & a]
                    if choices.size:
                        assignments[i] = int(np.bincount(choices).argmax())
            major.sort(key=lambda i: float(np.nonzero(labels == i)[1].mean()))
            for i in major:
                keep = np.isin(labels, [j for j, target in assignments.items() if target == i]) & a
                yy, xx = np.nonzero(keep)
                region = [max(0, int(xx.min())-4), max(0, int(yy.min())-4),
                          min(raw.width, int(xx.max())+5), min(a.shape[0], int(yy.max())+5)]
                isolated_pixels = row_pixels.copy()
                isolated_pixels[~keep] = 0
                region[1] += ys[row]; region[3] += ys[row]
                isolated.append((Image.fromarray(isolated_pixels), region))
        for col in range(count):
            key = f'{anim}_{col+1:02}'
            if isolated:
                isolated_image, region = isolated[col]
                crop = isolated_image.crop([region[0], region[1]-ys[row], region[2], region[3]-ys[row]])
            else:
                region = record.get('regions', {}).get(key, [xs[col], ys[row], xs[col+1], ys[row+1]])
                crop = clean.crop(region)
            bbox = crop.getbbox()
            if bbox is None:
                raise ValueError(f'{record["id"]}/{record["form"]}/{key}: empty cell')
            a = np.array(crop)[:, :, 3] > 0
            if a[0].any() or a[-1].any() or a[:, 0].any() or a[:, -1].any():
                raise ValueError(f'{key}: source touches crop edge; review for neighboring cells')
            # Dense middle body, excluding sparse antennae, weapon tips and feet.
            y0 = round(bbox[1]+(bbox[3]-bbox[1])*.35)
            y1 = max(y0+1, round(bbox[1]+(bbox[3]-bbox[1])*.8))
            occupied_x = np.nonzero(a[y0:y1])[1]
            center = float(np.median(occupied_x))
            frames.append(dict(key=key, anim=anim, col=col, row=row, crop=crop,
                               region=region, body_center=center, foot=bbox[3], bbox=bbox,
                               isolation='connected_components' if isolated else 'transparent_gutters'))
    scale = record['height']/float(np.median([f['bbox'][3]-f['bbox'][1] for f in frames[:4]]))
    folder = ROOT/'assets/art'/('monsters' if record['form']=='normal' else 'elitemonster')/record['id']
    (folder/'frames').mkdir(parents=True, exist_ok=True)
    stem = record['id']+('_elite' if record['form']=='elite' else '')
    (folder/(stem+'_source.png')).write_bytes(source.read_bytes())
    sheet = Image.new('RGBA', (CELL[0]*6, CELL[1]*5))
    animations = {}
    measurements = []
    hashes = set()
    for f in frames:
        size = tuple(max(1, round(n*scale)) for n in f['crop'].size)
        resized = f['crop'].resize(size, Image.Resampling.NEAREST)
        resized_bbox = resized.getbbox()
        xy = (round(ANCHOR[0]-f['body_center']*scale), ANCHOR[1]-resized_bbox[3])
        out = Image.new('RGBA', CELL)
        out.paste(resized, xy)
        bbox = out.getbbox()
        if bbox is None or bbox[0]<4 or bbox[1]<4 or bbox[2]>CELL[0]-4 or bbox[3]>CELL[1]-4:
            raise ValueError(f'{stem}/{f["key"]}: insufficient final padding')
        # No silently clipped pixels at the destination.
        if sum(out.getchannel('A').histogram()[1:]) != sum(resized.getchannel('A').histogram()[1:]):
            raise ValueError(f'{stem}/{f["key"]}: clipped pixels')
        digest = hashlib.sha256(out.tobytes()).hexdigest()
        if digest in hashes:
            raise ValueError(f'{stem}/{f["key"]}: identical duplicate frame')
        hashes.add(digest)
        filename = 'frames/'+f['key']+'.png'
        out.save(folder/filename, optimize=True)
        sheet.paste(out, (f['col']*CELL[0], f['row']*CELL[1]))
        animations.setdefault(f['anim'], {'fps':next(x[2] for x in ANIMS if x[0]==f['anim']),
                                          'loop':f['anim'] in ['idle','move'], 'frames':[]})['frames'].append(filename)
        measurements.append({'file':filename, 'source_crop':f['region'], 'source_body_center_x':f['body_center'],
                             'source_foot_y':f['foot'], 'source_isolation':f['isolation'], 'bbox':bbox, 'sha256':digest})
    sheet.save(folder/(stem+'_spritesheet.png'), optimize=True)
    manifest = dict(character_id=stem, name_ko=record['name'], form=record['form'], intended_rarity='common',
                    status='assets_only_unregistered', direction='right', cell_size=CELL, sheet_size=sheet.size,
                    anchor={'center_x':ANCHOR[0], 'foot_y':ANCHOR[1]}, columns=6, rows=5, animations=animations,
                    source=stem+'_source.png', sheet=stem+'_spritesheet.png', portrait=None,
                    source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(), design=record['design'],
                    generation={'tool':'image_gen', 'prompt':record['prompt']},
                    normalization={'alpha_threshold':128, 'resampling':'nearest', 'uniform_scale':scale,
                                   'rgb_keying':False, 'body_height_target':record['height']}, frames=measurements)
    (folder/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
    lines = ['[gd_resource type="SpriteFrames" load_steps=24 format=3]', '']
    for i,f in enumerate(frames):
        lines.append(f'[ext_resource type="Texture2D" path="res://{(folder/"frames"/(f["key"]+".png")).relative_to(ROOT)}" id="{i+1}"]')
    lines += ['', '[resource]', 'animations = [']
    index = 1
    for anim,count,fps,loop in ANIMS:
        entries = ', '.join('{"duration": 1.0, "texture": ExtResource("%d")}' % i for i in range(index,index+count))
        lines.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s},' % (entries,str(loop).lower(),anim,float(fps)))
        index += count
    lines += [']', '']
    (folder/(stem+'_animations.tres')).write_text('\n'.join(lines))
    preview = f'''[gd_scene load_steps=2 format=3]

[ext_resource type="SpriteFrames" path="res://{folder.relative_to(ROOT)}/{stem}_animations.tres" id="1"]

[node name="{stem}" type="Node2D"]

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
texture_filter = 1
sprite_frames = ExtResource("1")
animation = &"idle"
autoplay = "idle"
centered = false
offset = Vector2(-48, -68)
scale = Vector2(3, 3)
'''
    (folder/(stem+'_preview.tscn')).write_text(preview)
    print(stem, '23 frames', 'scale', round(scale,4), 'sheet', sheet.size)


if __name__ == '__main__':
    for record in json.loads(Path(sys.argv[1]).read_text()):
        package(record)
