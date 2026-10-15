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
    check(sheet.mode == 'RGBA' and sheet.size == (576, 400), 'RGBA sheet dimensions')
    check(manifest['anchor'] == {'center_x':48, 'foot_y':68}, 'common pivot')
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
            check(im.mode == 'RGBA' and im.size == (96,80), 'frame RGBA and size')
            check(set(np.unique(a[:,:,3])) == {0,255}, 'binary transparent alpha')
            check(bbox[3] == 68 and bbox[0] >= 4 and bbox[1] >= 4 and bbox[2] <= 92, 'feet and padding')
            cell = sheet.crop((col*96,row*80,(col+1)*96,(row+1)*80))
            check(cell.tobytes() == im.tobytes(), 'sheet matches split frame exactly')
            digest = hashlib.sha256(im.tobytes()).hexdigest()
            check(digest == manifest['frames'][index]['sha256'] and digest not in unique, 'unique unchanged frame')
            unique.add(digest)
            index += 1
        for col in range(count,6):
            check(sheet.crop((col*96,row*80,(col+1)*96,(row+1)*80)).getbbox() is None, 'unused cells transparent')
    stem = manifest['character_id']
    resource = (folder/(stem+'_animations.tres')).read_text()
    paths = re.findall(r'path="res://([^"]+)"',resource)
    check(len(paths) == 23 and all((ROOT/p).is_file() for p in paths), 'SpriteFrames paths')
    check('offset = Vector2(-48, -68)' in (folder/(stem+'_preview.tscn')).read_text(), 'preview pivot')
print(f'COMMON_MONSTER_ART forms={len(records)} frames={len(records)*23} checks={checks} PASS')
