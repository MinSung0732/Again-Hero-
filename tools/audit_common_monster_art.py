"""Static production PNG/manifest/SpriteFrames audit, no Godot or gameplay simulation."""
from pathlib import Path
import hashlib
import json
import re

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
records = json.loads((ROOT/'docs/COMMON_MONSTER_ART_SOURCES_20261015.json').read_text())
checks = 0


def check(condition, message):
    global checks
    checks += 1
    assert condition, message


check(len(records) == 14, 'seven normal plus seven elite forms')
for record in records:
    folder = (ROOT/record['source']).parent
    manifest = json.loads((folder/'manifest.json').read_text())
    source = folder/manifest['source']
    check(hashlib.sha256(source.read_bytes()).hexdigest() == manifest['source_sha256'], 'original source intact')
    sheet = Image.open(folder/manifest['sheet'])
    w,h = manifest['cell_size']
    ax,ay = manifest['anchor']['center_x'],manifest['anchor']['foot_y']
    check(sheet.mode == 'RGBA' and sheet.size == (w*6, h*5), 'RGBA sheet dimensions')
    check(manifest['normalization']['uniform_scale'] == 1.0 and manifest['normalization']['native_resolution'], 'common pivot')
    check(manifest['status'] == 'assets_only_unregistered', 'not gameplay registered')
    check(manifest['normalization']['rgb_keying'] is False, 'no black pixel removal')
    check(len(manifest['frames']) == 23, '23 frames')
    unique = set()
    index = 0
    for row, (anim, count) in enumerate([('idle',4),('move',6),('attack',6),('hit',3),('death',4)]):
        data = manifest['animations'][anim]
        check(len(data['frames']) == count and data['loop'] == (anim in ['idle','move']), 'animation contract')
        for col,path in enumerate(data['frames']):
            im = Image.open(folder/path)
            a = np.array(im)
            bbox = im.getbbox()
            check(im.mode == 'RGBA' and im.size == (w,h), 'frame RGBA and size')
            check(set(np.unique(a[:,:,3])) == {0,255}, 'binary transparent alpha')
            check(bbox[3] == ay and bbox[0] >= 4 and bbox[1] >= 4 and bbox[2] <= w-4, 'feet and padding')
            cell = sheet.crop((col*w,row*h,(col+1)*w,(row+1)*h))
            check(cell.tobytes() == im.tobytes(), 'sheet matches split frame exactly')
            digest = hashlib.sha256(im.tobytes()).hexdigest()
            check(digest == manifest['frames'][index]['sha256'] and digest not in unique, 'unique unchanged frame')
            f = manifest['frames'][index]
            source_crop = np.array(Image.open(source).convert('RGBA').crop(f['source_crop']))
            source_crop[:,:,3] = np.where(source_crop[:,:,3] >= 128,255,0)
            dx,dy = f['destination_offset']
            yy,xx = np.nonzero(a[:,:,3])
            check(np.array_equal(a[yy,xx],source_crop[yy-dy,xx-dx]), 'native source pixels retained exactly')
            unique.add(digest)
            index += 1
        for col in range(count,6):
            check(sheet.crop((col*w,row*h,(col+1)*w,(row+1)*h)).getbbox() is None, 'unused cells transparent')
    stem = manifest['character_id']
    resource = (folder/(stem+'_animations.tres')).read_text()
    paths = re.findall(r'path="res://([^"]+)"',resource)
    check(len(paths) == 23 and all((ROOT/p).is_file() for p in paths), 'SpriteFrames paths')
    check(f'offset = Vector2(-{ax}, -{ay})' in (folder/(stem+'_preview.tscn')).read_text(), 'preview pivot')
print(f'COMMON_MONSTER_ART forms={len(records)} frames={len(records)*23} checks={checks} PASS')
