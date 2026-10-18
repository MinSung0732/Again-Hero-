"""Compare all fourteen phase18 binding candidates using their full owners."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
from build_hero_combat_effect_fixture import method

CHANGED = ['_fire_projectile', '_activate_channel_skill', '_activate_shield',
           '_use_piercing_projectile_ultimate', '_prepare_contextual_damage_audio',
           '_tick_charm_state', '_apply_augment', '_level_up',
           '_prepare_ranged_ai_intent', '_refresh_hero_action_bindings']
NEW = ['_play_ordered_hero_audio', '_dispatch_augment_stack_hook']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--baseline', required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    out = args.destination.resolve()
    if out == repo or repo in out.parents: raise SystemExit('Use a directory outside the repository')
    out.mkdir(parents=True, exist_ok=True)
    def old(path): return subprocess.check_output(['git', 'show', args.baseline + ':' + path], cwd=repo, text=True)
    before = old('src/hero/hero.gd')
    after = (repo / 'src/hero/hero.gd').read_text()
    names = re.findall(r'^func (\w+)\(', before, re.M)
    for name in names:
        if name not in CHANGED: assert method(before, name) == method(after, name), name
    assert set(re.findall(r'^func (\w+)\(', after, re.M)) == set(names + NEW)
    def outer(source):
        for name in re.findall(r'^func (\w+)\(', source, re.M): source = source.replace(method(source, name).rstrip(), '')
        return ''.join(source.replace('var _hero_boundary_steering: Callable\n', '').split())
    assert outer(before) == outer(after), 'Other Hero declarations changed'
    for path in ['src/main/main.gd', 'src/battle/battle.gd']:
        assert old(path) == (repo / path).read_text(), path
    for path in ['src/data/hero_runtime_binding_catalog.gd', 'src/data/contextual_audio_catalog.gd']:
        assert (repo / path).read_text().startswith(old(path)), path
    old_presentation = old('src/data/hero_presentation_catalog.gd')
    presentation = (repo / 'src/data/hero_presentation_catalog.gd').read_text()
    prefix = old_presentation[:old_presentation.index('const EVENT_AUDIO :=')]
    assert presentation.startswith(prefix)
    assert old_presentation[old_presentation.index('static func get_event_audio'):].rstrip() == presentation[presentation.index('static func get_event_audio'):presentation.index('const ORDERED_EVENT_AUDIO')].rstrip()
    print(f'Other Hero methods identical: {len(names)-len(CHANGED)}; other declarations/Main/Battle/prior catalog sections identical')
    for path in ['src/hero/hero_action_intent.gd', 'src/hero/hero_action_port.gd',
                 'src/data/hero_runtime_binding_catalog.gd', 'src/data/hero_presentation_catalog.gd', 'src/data/contextual_audio_catalog.gd']:
        dest = out / path; dest.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(repo / path, dest)
    header = (repo / 'tests/fixtures/hero_remaining_binding_fixture.gd').read_text()
    for label, source in [('before', before), ('after', after)]:
        text = header
        cache = re.search(r'^# Retained callbacks:.*?(?=^var sprite_frame_dir)', source, re.M | re.S).group()
        text += '\n' + cache
        for name in CHANGED + ['_physics_process_actions', '_play_bound_hero_audio'] + (NEW if label == 'after' else []): text += '\n' + method(source, name)
        (out / (label + '.gd')).write_text(text)
    shutil.copy2(repo / 'tests/hero_remaining_binding_policy_smoke.gd', out / 'smoke.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="RemainingBindingFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__': main()
