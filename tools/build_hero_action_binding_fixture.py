"""Compare the complete action owner using the real action intent/port."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
from build_hero_combat_effect_fixture import method


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
        return subprocess.check_output(['git', 'show', args.baseline + ':' + path], cwd=repo, text=True)

    before = old('src/hero/hero.gd')
    after = (repo / 'src/hero/hero.gd').read_text()
    names = re.findall(r'^func (\w+)\(', before, re.M)
    for name in names:
        if name != '_physics_process_actions':
            assert method(before, name) == method(after, name), name
    assert set(re.findall(r'^func (\w+)\(', after, re.M)) == set(names + ['_refresh_hero_action_bindings'])
    cache_fields = re.search(r'^# Retained callbacks:.*?^var _hero_common_runtime_tick: Callable\n', after, re.M | re.S).group()

    def outer(source):
        for name in re.findall(r'^func (\w+)\(', source, re.M):
            source = source.replace(method(source, name).rstrip(), '')
        return ''.join(source.replace(cache_fields, '').split())

    assert outer(before) == outer(after), 'Unexpected Hero declarations changed'
    for path in ['src/main/main.gd', 'src/battle/battle.gd', 'src/data/hero_presentation_catalog.gd']:
        assert old(path) == (repo / path).read_text(), path
    catalog = (repo / 'src/data/hero_runtime_binding_catalog.gd').read_text()
    assert catalog.startswith(old('src/data/hero_runtime_binding_catalog.gd'))
    print(f'Unchanged Hero methods: {len(names) - 1}; Main/Battle/presentation and prior runtime binding data identical')
    for path in ['src/hero/hero_action_intent.gd', 'src/hero/hero_action_port.gd', 'src/data/hero_runtime_binding_catalog.gd']:
        dest = out / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(repo / path, dest)
    header = (repo / 'tests/fixtures/hero_action_binding_fixture.gd').read_text()
    for label, source in [('before', before), ('after', after)]:
        text = header
        if label == 'after':
            text += '\nconst HERO_RUNTIME_BINDINGS = preload("res://src/data/hero_runtime_binding_catalog.gd")\n' + cache_fields
            text += '\n' + method(source, '_refresh_hero_action_bindings')
        for name in ['_physics_process_actions', '_prepare_ranged_ai_intent']:
            text += '\n' + method(source, name)
        (out / (label + '.gd')).write_text(text)
    shutil.copy2(repo / 'tests/hero_action_binding_policy_smoke.gd', out / 'smoke.gd')
    shutil.copy2(repo / 'tests/hero_action_binding_policy_benchmark.gd', out / 'benchmark.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="ActionBindingFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
