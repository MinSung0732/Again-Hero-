"""Extract actual pre/post Hero effect setup methods into a small Godot project."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess

CHANGED = [
    '_apply_stage2_rogue_effect_visuals',
    '_apply_stage3_fighter_effect_visuals',
    '_apply_stage4_gunner_effect_visuals',
]
HELPERS = ['_build_stage2_effect_frames', '_add_prefixed_effect_animation',
           '_apply_stage1_shield_visual', '_apply_stage1_channel_visual']
REMOVED = ['_build_stage2_effect_frames', '_add_prefixed_effect_animation']
NEW = ['_configure_combat_effect_profile', '_build_bound_effect_frames']


def method(source, name):
    start = re.search(r'^func ' + re.escape(name) + r'\(', source, re.M)
    assert start, name
    end = re.search(r'^(?:(?:static )?func |const |var |signal |enum |class |@onready |@export)',
                    source[start.end():], re.M)
    return source[start.start():start.end() + end.start() if end else len(source)].rstrip() + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--baseline', required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    out = args.destination.resolve()
    if out == repo or repo in out.parents:
        raise SystemExit('Use a directory outside the repository')
    out.mkdir(parents=True, exist_ok=True)

    def old(path):
        return subprocess.check_output(['git', 'show', args.baseline + ':' + path],
                                       cwd=repo, text=True)

    before = old('src/hero/hero.gd')
    after = (repo / 'src/hero/hero.gd').read_text()
    names = re.findall(r'^func (\w+)\(', before, re.M)
    for name in names:
        if name not in CHANGED + REMOVED:
            assert method(before, name) == method(after, name), name
    for path in ['src/main/main.gd', 'src/battle/battle.gd']:
        assert old(path) == (repo / path).read_text(), path
    catalog = (repo / 'src/data/hero_presentation_catalog.gd').read_text()
    assert catalog.startswith(old('src/data/hero_presentation_catalog.gd'))
    print(f'Unchanged Hero methods: {len(names) - len(CHANGED) - len(REMOVED)}; Main/Battle and prior catalog identical')
    (out / 'src/data').mkdir(parents=True, exist_ok=True)
    (out / 'src/data/hero_presentation_catalog.gd').write_text(catalog)
    header = '''extends Node2D
const HERO_PRESENTATION = preload("res://src/data/hero_presentation_catalog.gd")
var hero_archetype: String = "unknown"
var hero_id: String = "other"
var rogue_attack_effect: AnimatedSprite2D
var channel_effect: AnimatedSprite2D
var shield_effect: AnimatedSprite2D
var paths: Array = []
var load_states: Array = []
var signals_seen: Array = []
var textures: Dictionary = {}
var missing: Array = []
var missing_all: bool = false
var texture_size := Vector2(64, 96)
func _init():
\trogue_attack_effect = AnimatedSprite2D.new()
\tchannel_effect = AnimatedSprite2D.new()
\tshield_effect = AnimatedSprite2D.new()
\tvar index := 0
\tfor sprite in [rogue_attack_effect, channel_effect, shield_effect]:
\t\tadd_child(sprite)
\t\tvar frames := SpriteFrames.new()
\t\tframes.add_animation("old")
\t\tfor i in range(3):
\t\t\tvar texture := GradientTexture2D.new()
\t\t\ttexture.set_meta("fixture_path", "old_%d" % i)
\t\t\tframes.add_frame("old", texture)
\t\tsprite.sprite_frames = frames
\t\tsprite.play("old")
\t\tsprite.frame = 2
\t\tsprite.frame_progress = 0.25
\t\tsprite.visible = true
\t\tsprite.position = Vector2(13, 17)
\t\tsprite.offset = Vector2(3, 7)
\t\tsprite.scale = Vector2(2, 3)
\t\tsprite.modulate = Color(0.2, 0.3, 0.4, 0.5)
\t\tsprite.rotation = 0.4
\t\tsprite.z_index = 7
\t\tsprite.speed_scale = 1.25
\t\tsprite.animation_changed.connect(record_signal.bind(index, "animation"))
\t\tsprite.sprite_frames_changed.connect(record_signal.bind(index, "frames"))
\t\tsprite.frame_changed.connect(record_signal.bind(index, "frame"))
\t\tindex += 1
func record_signal(index, kind):
\tsignals_seen.append([index, kind, states()])
func sprite_state(sprite):
\tvar animations: Array = []
\tif sprite.sprite_frames != null:
\t\tfor animation in sprite.sprite_frames.get_animation_names():
\t\t\tvar frame_paths: Array = []
\t\t\tfor i in range(sprite.sprite_frames.get_frame_count(animation)):
\t\t\t\tframe_paths.append(sprite.sprite_frames.get_frame_texture(animation, i).get_meta("fixture_path"))
\t\t\tanimations.append([animation, sprite.sprite_frames.get_animation_speed(animation), sprite.sprite_frames.get_animation_loop(animation), frame_paths])
\treturn [animations, sprite.visible, sprite.position, sprite.offset, sprite.scale, sprite.modulate, sprite.rotation, sprite.z_index, sprite.texture_filter, sprite.animation, sprite.frame, sprite.frame_progress, sprite.speed_scale, sprite.is_playing()]
func states():
\treturn [sprite_state(rogue_attack_effect), sprite_state(channel_effect), sprite_state(shield_effect)]
func snapshot():
\treturn [paths, load_states, signals_seen, states()]
func _load_stage1_texture(path: String) -> Texture2D:
\tpaths.append(path)
\tload_states.append(states())
\tif missing_all or path in missing:
\t\treturn null
\tif not textures.has(path):
\t\tvar texture := GradientTexture2D.new()
\t\ttexture.width = int(texture_size.x)
\t\ttexture.height = int(texture_size.y)
\t\ttexture.set_meta("fixture_path", path)
\t\ttextures[path] = texture
\treturn textures[path]
'''
    for label, source in [('before', before), ('after', after)]:
        text = header
        for line in source.splitlines():
            if re.match(r'^const STAGE[1234]_\w+ :=', line) and 'AUDIO' not in line:
                text += line + '\n'
        for name in CHANGED + [name for name in HELPERS if label == 'before' or name not in REMOVED] + (NEW if label == 'after' else []):
            text += '\n' + method(source, name)
        (out / (label + '.gd')).write_text(text)
    shutil.copy2(repo / 'tests/hero_combat_effect_policy_smoke.gd', out / 'smoke.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="CombatEffectPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
