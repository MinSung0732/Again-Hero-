"""Reproduce effect/icon export size comparison; excludes native actor scenes."""
from pathlib import Path
import argparse, shutil, subprocess, sys
parser = argparse.ArgumentParser()
parser.add_argument('destination',type=Path)
parser.add_argument('--optimized',action='store_true')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
out = args.destination.resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_art_fixture.py'),str(out)],check=True)
shutil.copytree(repo/'assets/art/UI/hero_augments',out/'assets/art/UI/hero_augments',dirs_exist_ok=True)
shutil.copytree(repo/'addons/againhero_oauth',out/'addons/againhero_oauth',dirs_exist_ok=True)
shutil.copyfile(repo/'tests/hero_effect_export_smoke.gd',out/'PackTest.gd')
(out/'export_presets.cfg').write_text('''[preset.0]
name="Pack"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter="*.png,*.json"
exclude_filter=""
[preset.0.options]
binary_format/architecture="x86_64"
''')
project = '''config_version=5
[application]
config/name="EffectOptimizationPack"
run/main_scene="res://PackTest.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
'''
if args.optimized:
    project += '\n[editor_plugins]\nenabled=PackedStringArray("res://addons/againhero_oauth/plugin.cfg")\n'
(out/'project.godot').write_text(project)
(out/'PackTest.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://PackTest.gd" id="1"]\n[node name="PackTest" type="Node"]\nscript = ExtResource("1")\n')
print('Export Pack using --headless --editor --export-pack; run only optimized PCK for exclusion assertions.')
