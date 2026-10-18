"""Focused cloud policy fixture: production transport/gateway/overlay, placeholder art."""
from pathlib import Path
import re, shutil, subprocess, sys
from PIL import Image
repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable, str(repo / 'tools/build_cloud_rpc_fixture.py'), str(out)], check=True)
queue = ['tests/cloud_policy_smoke.gd', 'tests/cloud_auth_recovery_smoke.gd',
         'tests/cloud_profile_retry_smoke.gd', 'tests/cloud_save_smoke.gd',
         'src/ui/cloud_connection_overlay.gd', 'src/systems/scene_transition.gd',
         'src/network/login_gateway.gd']
seen = set()
while queue:
    path = queue.pop()
    if path in seen:
        continue
    seen.add(path)
    source, dest = repo / path, out / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    if source.exists():
        shutil.copy2(source, dest)
    elif dest.suffix == '.png':
        Image.new('RGBA', (512, 512), (60, 40, 80, 255)).save(dest)
    elif dest.suffix == '.tres':
        dest.write_text('[gd_resource type="StyleBoxFlat" format=3]\n[resource]\n')
    else:
        raise SystemExit('Missing nonvisual dependency: ' + path)
    if path == 'src/data/monster_catalog.gd':
        dest.write_text(re.sub(r'preload\("res://src/monsters/[^"\n]+\.tscn"\)', 'null', dest.read_text()))
    if dest.suffix in ['.gd', '.tres']:
        queue.extend(re.findall(r'preload\("res://([^"\n]+)"\)', dest.read_text()))
        queue.extend(re.findall(r'extends "res://([^"\n]+)"', dest.read_text()))
project = (out / 'project.godot').read_text()
project = project.replace('AgainHeroNicknameFixture', 'AgainHeroCloudPolicyFixture')
project = project.replace('*res://fixture_cloud.gd', '*res://src/network/cloud_store.gd')
project = project.replace('*res://fixture_gateway.gd', '*res://src/network/login_gateway.gd')
project = project.replace('[display]', 'SceneTransition="*res://src/systems/scene_transition.gd"\nCloudConnectionOverlay="*res://src/ui/cloud_connection_overlay.gd"\n[display]')
(out / 'project.godot').write_text(project)
(out / 'warmup.gd').write_text('extends Node\nsignal progress_changed(done: int, total: int)\nfunc get_texture(_path: String) -> Texture2D: return null\n')
print('Production gateway/overlay/policy closure:', len(seen))
