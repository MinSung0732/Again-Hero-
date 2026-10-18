"""Run production BGM/cutscene code and real music with isolated presentation/SFX."""
from pathlib import Path
import argparse
import re
import shutil
from PIL import Image

p = argparse.ArgumentParser()
p.add_argument('destination', type=Path)
a = p.parse_args()
repo = Path(__file__).resolve().parents[1]
out = a.destination.resolve()
if out == repo or repo in out.parents:
    raise SystemExit('Use a directory outside the repository')
out.mkdir(parents=True, exist_ok=True)

def write(path, content):
    dest = out / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content)

for path in ['src/audio/game_audio.gd', 'src/audio/audio_settings.gd',
             'src/data/game_audio_catalog.gd', 'src/data/contextual_audio_catalog.gd',
             'src/data/stage_intro_dialogues.gd', 'src/ui/stage_intro_cutscene.gd',
             'tests/dialogue_bgm_smoke.gd', 'tests/dialogue_bgm_mix_smoke.gd', 'default_bus_layout.tres',
             'assets/audio/bgm/frontend_loop.ogg', 'assets/audio/bgm/talk_background.wav']:
    dest = out / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(repo / path, dest)
write('project.godot', '''config_version=5
[application]
config/name="Dialogue BGM isolated fixture"
config/use_custom_user_dir=true
config/custom_user_dir_name="AgainHeroDialogueBGMFixture"
[autoload]
AudioSettings="*res://src/audio/audio_settings.gd"
GameAudio="*res://src/audio/game_audio.gd"
PresentationWarmup="*res://tests/warmup.gd"
[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
[rendering]
renderer/rendering_method="gl_compatibility"
''')
# Explicit non-BGM substitutes; no production BGM, page, or timing edits.
write('src/audio/event_sfx_bank.gd', '''extends Node
var honor_tree_pause := true
func configure(_data, _battle=null, _clock=false): pass
func stop_cue(_id): pass
func stop_all(): pass
func play_cue(_id): pass
''')
write('src/data/monster_catalog.gd', 'extends RefCounted\nstatic func get_rarity(_id): return "common"\n')
write('src/systems/player_profile.gd', '''extends RefCounted
static func display_name(): return "마왕"
static func portrait_path(_kind="", _expression=""): return ""
''')
write('tests/warmup.gd', '''extends Node
func get_texture(_path) -> Texture2D: return null
''')
write('src/ui/pixel_panel_skin.gd', '''extends RefCounted
static func apply(_button): pass
static func skin_style(style): return style
''')
Image.new('RGBA', (16, 16), (100, 100, 100, 255)).save(out/'tests/portrait.png')
write('tests/theme.tres', '[gd_resource type="Theme" format=3]\n[resource]\n')
scene = (repo/'src/ui/StageIntroCutscene.tscn').read_text()
scene = re.sub(r'(type="Texture2D" path=")[^"]+', r'\1res://tests/portrait.png', scene)
scene = scene.replace('res://src/ui/game_theme.tres', 'res://tests/theme.tres')
write('src/ui/StageIntroCutscene.tscn', scene)
print('Production GameAudio/StageIntroCutscene, real music; SFX/profile/skin/art substitutes.')
