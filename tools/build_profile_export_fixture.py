"""Real cosmetic store/texture helpers, imported-only PNGs in exported PCK."""
from pathlib import Path
import subprocess,sys,shutil
repo = Path(__file__).resolve().parents[1]; out = Path(sys.argv[1]).resolve()
# Helper classes are extracted from actual UI methods; no duplicate implementation.
def method(path,end):
    text = (repo/path).read_text(); return text[text.index('func _texture('):text.index(end,text.index('func _texture('))]
out.mkdir(parents=True,exist_ok=True)
(out/'tests').mkdir(exist_ok=True)
(out/'tests/pickup_texture_harness.gd').write_text('extends RefCounted\nvar lobby: Control\nvar textures: Dictionary = {}\n'+method('src/ui/shop_pickup_view.gd','func install('))
(out/'tests/profile_texture_harness.gd').write_text('extends RefCounted\nvar lobby: Control\nvar textures: Dictionary = {}\n'+method('src/ui/lobby_profile_view.gd','func _button('))
# Existing closure builder can resolve the temporary harness paths from the fixture.
import re
queue=['tests/profile_export_smoke.gd']; seen=set()
while queue:
    path=queue.pop()
    if path in seen: continue
    seen.add(path)
    source=repo/path; destination=out/path
    if not source.exists() and destination.exists(): continue
    destination.parent.mkdir(parents=True,exist_ok=True)
    content=source.read_text()
    if path=='src/data/monster_catalog.gd': content=re.sub(r'preload\("res://src/monsters/[^"\n]+\.tscn"\)','null',content)
    destination.write_text(content)
    queue.extend(re.findall(r'preload\("res://([^"\n]+\.gd)"\)',content))
paths=['assets/art/demonking/demonking_portrait_male.png','assets/art/demonking/demonking_portrait_female.png','assets/art/UI/profile_v1/banner_male.png','assets/art/UI/profile_v1/banner_female.png','assets/art/Transcendent_monster/zeus/zeus_pickup_banner.png','assets/art/Transcendent_monster/zeus/zeus_icon.png','assets/art/Transcendent_monster/zeus/zeus_banner.png']
for path in paths:
    target=out/path; target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(repo/path,target)
(out/'warmup.gd').write_text('extends Node\nfunc get_texture(_path: String) -> Texture2D: return null\n')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ProfileExportFixture"\nrun/main_scene="res://Test.tscn"\n[autoload]\nPresentationWarmup="*res://warmup.gd"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
(out/'Test.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tests/profile_export_smoke.gd" id="1"]\n[node name="Test" type="Node"]\nscript = ExtResource("1")\n')
(out/'export_presets.cfg').write_text('[preset.0]\nname="Pack"\nplatform="Linux"\nrunnable=true\nexport_filter="all_resources"\ninclude_filter=""\nexclude_filter=""\n[preset.0.options]\nbinary_format/architecture="x86_64"\n')
print('Fixture scripts',len(seen))
