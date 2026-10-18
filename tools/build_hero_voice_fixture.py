"""Build a small Godot project with real voices/player/settings/UI and extracted Battle owners."""
import argparse
from pathlib import Path
import shutil
from build_hero_combat_effect_fixture import method


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    out = args.destination.resolve()
    if out == repo or repo in out.parents:
        raise SystemExit('Use a destination outside the repository')
    out.mkdir(parents=True, exist_ok=True)
    paths = ['src/audio/audio_settings.gd', 'src/audio/hero_voice_player.gd',
             'src/data/hero_voice_catalog.gd', 'src/data/hero_character_catalog.gd', 'src/data/hero_reveal_catalog.gd',
             'src/ui/hero_reveal_cutscene.gd', 'src/ui/hero_reveal_magic.gdshader',
             'src/ui/skill_unlock_cutscene.gd', 'src/ui/SkillUnlockCutscene.tscn']
    paths.extend(str(p.relative_to(repo)) for p in (repo/'assets/audio/sfx/hero_voices').rglob('*.wav'))
    for path in paths:
        dest = out/path
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(repo/path, dest)
    scene = (repo/'src/ui/HeroRevealCutscene.tscn').read_text()
    scene = scene.replace('res://src/ui/game_theme.tres', 'res://fixture_theme.tres')
    scene = scene.replace('res://assets/art/UI/hero_reveal_v2/reveal_chamber.png', 'res://fixture_texture.tres')
    (out/'src/ui/HeroRevealCutscene.tscn').write_text(scene)
    (out/'fixture_texture.tres').write_text('[gd_resource type="GradientTexture2D" format=3]\n[resource]\nwidth = 64\nheight = 64\n')
    (out/'fixture_theme.tres').write_text('[gd_resource type="Theme" format=3]\n[resource]\n')
    header = (repo/'tests/fixtures/hero_voice_battle_fixture.gd').read_text()
    battle = (repo/'src/battle/battle.gd').read_text()
    for name in ['_finish_battle', '_on_hero_died', '_on_run_time_up',
                 '_finish_hero_boss_victory', 'finish_hero_boss_timeout', 'finish_abandoned_run']:
        header += '\n'+method(battle, name)
    (out/'battle_fixture.gd').write_text(header)
    shutil.copy2(repo/'tests/hero_voice_smoke.gd', out/'smoke.gd')
    main_source = (repo/'src/main/main.gd').read_text()
    hooks = 'extends Node\nvar hero_voice: Node\nvar _stage_intro_stage_id := "stage_8"\nvar battle_started := false\nfunc _start_battle_after_intro(_stage_id: String): battle_started = true\n'
    for name in ['_on_hero_reveal_finished', '_on_skill_artwork_revealed']:
        hooks += '\n' + method(main_source, name)
    (out/'main_hooks.gd').write_text(hooks)
    warmup = (repo/'src/systems/presentation_warmup.gd').read_text()
    (out/'warmup_fixture.gd').write_text('extends Node\nvar _common := {}\nvar _destination := {}\n' + method(warmup, 'get_texture'))
    (out/'Smoke.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://smoke.gd" id="1"]\n[node name="Smoke" type="Node"]\nscript = ExtResource("1")\n')
    (out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="HeroVoiceFixture"\nrun/main_scene="res://Smoke.tscn"\n[autoload]\nAudioSettings="*res://src/audio/audio_settings.gd"\nPresentationWarmup="*res://warmup_fixture.gd"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
