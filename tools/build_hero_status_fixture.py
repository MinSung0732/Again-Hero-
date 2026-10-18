"""Extract status drawing and animation routing for behavior comparison."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess

from build_hero_combat_effect_fixture import method

CHANGED = ['_draw_combat_status_overlay', '_hero_animation_priority',
           '_on_hero_sprite_frame_or_animation_changed']
NEW = ['_draw_status_resource_bar', '_get_status_displayed_cells']
PLAYBACK = ['_is_current_hero_animation_protected', '_play_stage1_animation',
            '_restart_stage1_animation']


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
        if name not in CHANGED:
            assert method(before, name) == method(after, name), name
    assert set(re.findall(r'^func (\w+)\(', after, re.M)) == set(names + NEW)

    def outer(source):
        for name in re.findall(r'^func (\w+)\(', source, re.M):
            source = source.replace(method(source, name).rstrip(), '')
        return ''.join(source.split())

    assert outer(before) == outer(after), 'Unexpected Hero declaration change'
    for path in ['src/main/main.gd', 'src/battle/battle.gd']:
        assert old(path) == (repo / path).read_text(), path
    catalog = (repo / 'src/data/hero_presentation_catalog.gd').read_text()
    assert catalog.startswith(old('src/data/hero_presentation_catalog.gd'))
    print(f'Unchanged Hero methods: {len(names) - len(CHANGED)}; Main/Battle, other declarations and prior catalog identical')
    (out / 'src/data').mkdir(parents=True, exist_ok=True)
    (out / 'src/data/hero_presentation_catalog.gd').write_text(catalog)
    header = (repo / 'tests/fixtures/hero_status_fixture.gd').read_text()
    for label, source in [('before', before), ('after', after)]:
        text = header + '\n' + re.search(r'^const HERO_ANIMATION_DUPLICATE_RESTART_GUARD_MSEC := .*$', source, re.M).group() + '\n'
        for name in CHANGED + PLAYBACK + (NEW if label == 'after' else []):
            text += '\n' + method(source, name)
        (out / (label + '.gd')).write_text(text)
    shutil.copy2(repo / 'tests/hero_status_policy_smoke.gd', out / 'smoke.gd')
    shutil.copy2(repo / 'tests/hero_status_policy_benchmark.gd', out / 'benchmark.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="HeroStatusFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
