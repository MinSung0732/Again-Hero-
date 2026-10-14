"""Real textures/runtime and exact draw dispatch, native GPU commands recorded."""
from pathlib import Path
import subprocess,sys,shutil
repo=Path(__file__).resolve().parents[1]; out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_weapon_art_smoke.gd'],check=True)
shutil.copytree(repo/'assets/art/effects/hero_weapon_v2',out/'assets/art/effects/hero_weapon_v2',dirs_exist_ok=True)
s=(repo/'src/hero_mode/hero_weapon_runtime.gd').read_text(); draw=s[s.index('func draw()'):]
draw=draw.replace('hero.draw_','hero.record_draw_')
(out/'tests/weapon_art_draw_harness.gd').write_text('''extends RefCounted
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const EMPTY_ART: Array[Texture2D] = []
var hero
var effects: Array = []
var projectiles: Array = []
var fields: Array = []
var visual_clock := 0.25
'''+draw)
