"""Validate delivered PNGs against native imagegen source pixels and manifests."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
checks = 0


def check(condition, label):
    global checks
    checks += 1
    assert condition, label


for folder in sorted((ROOT/'assets/art/projectiles/frontier').iterdir()):
    if not folder.is_dir():
        continue
    m = json.loads((folder/'manifest.json').read_text())
    source_file = folder/m['source_file']
    source = Image.open(source_file)
    source.load()
    check(source.mode == 'RGBA', f'{folder.name}: source RGBA')
    check(hashlib.sha256(source_file.read_bytes()).hexdigest() == m['source_sha256'], 'source SHA')
    raw = np.array(source)
    sheet = Image.open(folder/f'{folder.name}_spritesheet.png')
    sheet.load()
    check(sheet.mode == 'RGBA' and list(sheet.size) == m['sheet_size'], 'sheet manifest size')
    packed = np.array(sheet)
    opaque = packed[:, :, 3] != 0
    check(set(np.unique(packed[:, :, 3])) == {0, 255}, 'binary transparent boundary')
    w,h = m['cell_size']
    unique = set()
    for i, filename in enumerate(m['animations']['projectile']['frames']):
        image = Image.open(folder/filename)
        image.load()
        frame = np.array(image)
        check(image.mode == 'RGBA' and image.size == (w,h), 'RGBA shared canvas')
        x,y = (i%2)*w, (i//2)*h
        check(np.array_equal(frame,packed[y:y+h,x:x+w]), 'individual frame equals sheet')
        sw,sh = m['source_cell_size']
        original = raw[(i//2)*sh:(i//2+1)*sh,(i%2)*sw:(i%2+1)*sw].copy()
        original[:,:,3] = np.where(original[:,:,3] >= 128,255,0)
        original[original[:,:,3] == 0,:3] = 0
        aligned = Image.new('RGBA',(w,h))
        ax,ay = m['source_anchors'][i]
        aligned.paste(Image.fromarray(original),(w//2-ax,h//2-ay))
        check(np.array_equal(frame,np.array(aligned)), 'native source pixels retained at integer offset')
        check(np.count_nonzero(frame[:,:,3]) == np.count_nonzero(original[:,:,3]), 'alignment loses no opaque pixels')
        check(not frame[0,:,3].any() and not frame[-1,:,3].any() and not frame[:,0,3].any() and not frame[:,-1,3].any(), 'no clipped border')
        check(image.getbbox() == tuple(m['bounds'][i]), 'manifest bounds')
        unique.add(hashlib.sha256(image.tobytes()).hexdigest())
    check(len(unique) == 4, 'four genuinely different animation frames')
    check(m['display_scale'] > 0 and m['animations']['projectile']['loop'], 'presentation metadata')
print('FRONTIER_PROJECTILE_PNG_AUDIT checks=', checks)
