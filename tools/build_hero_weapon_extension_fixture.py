"""Build an asset-light Godot fixture for 100-kit data and 40 generic casts.
Native scene actors are omitted here; use full-project growth smoke for those.
"""
from pathlib import Path
import argparse
import re
import shutil

parser = argparse.ArgumentParser()
parser.add_argument('destination', type=Path)
parser.add_argument('--script', default='tests/hero_weapon_extension_smoke.gd')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
output = args.destination.resolve()
if output == repo or repo in output.parents:
    raise SystemExit('Fixture must be outside the repository')
output.mkdir(parents=True, exist_ok=True)
(output / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Hero weapon extension fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
queue = [args.script]
seen = set()
while queue:
    path = queue.pop()
    if path in seen:
        continue
    seen.add(path)
    source = repo / path
    if not source.is_file():
        raise SystemExit('Missing fixture dependency: ' + path)
    destination = output / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.suffix not in ['.gd', '.tscn', '.tres']:
        shutil.copyfile(source, destination)
        continue
    content = source.read_text()
    if path == 'src/hero_mode/hero_weapon_native_runtime.gd':
        content = re.sub(r'const SCENES := \{.*?\n\}', 'const SCENES := {}', content, count=1, flags=re.S)
    if path == 'src/hero_mode/hero_survival_identity_runtime.gd':
        content = content.replace('preload("res://src/hero/archmage_projectile.gd").ORB_FRAME_PATHS', 'PackedStringArray()')
    destination.write_text(content)
    queue.extend(re.findall(r'path="res://([^"]+)"', content))
    queue.extend(re.findall(r'preload\("res://([^\"]+)"\)', content))
print('Fixture files:', len(seen))
print('Native actor scenes and unused archmage frame constants omitted; all new generic cast/data functions retained.')
