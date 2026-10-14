"""Isolate production texture helpers and hero atlases; test an exported PCK."""
from pathlib import Path
import shutil
import re
import sys
repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=True)
pending = ['src/ui/hero_hud_art.gd', 'src/ui/hero_augment_icons.gd']
seen = set()
while pending:
    path = pending.pop()
    if path in seen: continue
    seen.add(path)
    target = out/path
    target.parent.mkdir(parents=True, exist_ok=True)
    content = (repo/path).read_text()
    if path == "src/data/monster_catalog.gd":
        content = re.sub(r'preload\("res://src/monsters/[^"\n]+\.tscn"\)', "null", content)
    target.write_text(content)
    pending.extend(re.findall(r'preload\("res://([^"\n]+\.gd)"\)', (repo/path).read_text()))
for folder in ['hero_augments', 'hero_hud']:
    shutil.copytree(repo/'assets/art/UI'/folder, out/'assets/art/UI'/folder, dirs_exist_ok=True)
art = out/'assets/test'; art.mkdir(parents=True, exist_ok=True)
(art/'panel.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect x="4" y="4" width="24" height="24" fill="#ffcc00"/></svg>')
from PIL import Image
image = Image.new('RGBA',(32,32)); image.paste((255,180,0,255),(4,4,28,28)); image.save(art/'panel.png')
source = (repo/'src/lobby/lobby.gd').read_text()
helpers = source[source.index('func _load_png_texture_direct('):source.index('func _apply_content_card_skin(')]
(out/'helpers.gd').write_text('extends RefCounted\n'+helpers)
(out/'warmup.gd').write_text('extends Node\nfunc get_texture(_path: String) -> Texture2D: return null\nfunc get_cropped(_path: String) -> Texture2D: return null\n')
(out/'project.godot').write_text('''config_version=5
[application]
config/name="LobbyExportFixture"
run/main_scene="res://Test.tscn"
[autoload]
PresentationWarmup="*res://warmup.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
(out/'export_presets.cfg').write_text('''[preset.0]
name="Pack"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""
[preset.0.options]
binary_format/architecture="x86_64"
''')
(out/'Test.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://test.gd" id="1"]\n[node name="Test" type="Node"]\nscript = ExtResource("1")\n')
(out/'test.gd').write_text('''extends Node
const HUD := preload("res://src/ui/hero_hud_art.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		failures += 1
func _ready() -> void:
	var loader = preload("res://helpers.gd").new()
	check(HUD.icon("damage") != null, "HUD imported atlas")
	check(ICONS.WEAPONS != null and ICONS.UNIQUE_WEAPONS != null and ICONS.PASSIVES != null, "augment imported atlases")
	check(loader._load_ui_texture_resource("") == null, "empty avatar path")
	for id in ICONS.DATA.WEAPONS:
		check(ICONS.texture(id) != null, "weapon icon: " + id)
	for id in ICONS.DATA.PASSIVES:
		check(ICONS.texture(id) != null, "passive icon: " + id)
	for extension in ["svg", "png"]:
		var path: String = "res://assets/test/panel." + extension
		check(ResourceLoader.exists(path), "imported resource exists")
		check(not FileAccess.file_exists(path), "raw source excluded from export")
		var texture = loader._load_ui_texture_resource(path)
		check(texture != null and texture.get_size() == Vector2(32,32), "PCK texture loading")
		check(loader._load_svg_texture_direct(path) != null, "SVG imported loading")
		check(loader._load_png_texture_direct(path) != null, "PNG imported loading")
		var crop = loader._load_png_texture_cropped(path)
		check(crop != null and crop.atlas == texture and crop.region == Rect2(4,4,24,24), "crop atlas")
		var top = loader._load_png_texture_top_region(path, 0.5)
		check(top != null and top.region == Rect2(4,4,24,12), "top atlas")
	print("Lobby exported texture checks: ", checks, " checks / failures: ", failures)
	get_tree().quit(0 if failures == 0 else 1)
''')
print(out)
