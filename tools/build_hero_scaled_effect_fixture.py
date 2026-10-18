"""Compare actual pre/post scaled effects and the Stage1-4 setup sequence."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess

from build_hero_combat_effect_fixture import method

CHANGED = ['_apply_stage1_shield_visual', '_apply_stage1_channel_visual']
NEW = ['_configure_scaled_effect_profile', '_reset_scaled_effect_visual']
SETUP = ['_apply_stage2_rogue_effect_visuals', '_apply_stage3_fighter_effect_visuals',
         '_apply_stage4_gunner_effect_visuals', '_configure_combat_effect_profile',
         '_build_bound_effect_frames']


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
        if name not in CHANGED:
            assert method(before, name) == method(after, name), name
    assert set(re.findall(r'^func (\w+)\(', after, re.M)) == set(names + NEW)
    # Verify the only non-function changes are the seven moved effect constants.
    def outer(source):
        for name in re.findall(r'^func (\w+)\(', source, re.M):
            source = source.replace(method(source, name).rstrip(), '')
        source = re.sub(r'^const STAGE1_(?:SHIELD|CHANNEL)_EFFECT_\w+ := .*\n', '', source, flags=re.M)
        return ''.join(source.split())
    assert outer(before) == outer(after), 'Unexpected Hero declarations changed'
    for path in ['src/main/main.gd', 'src/battle/battle.gd']:
        assert old(path) == (repo / path).read_text(), path
    catalog = (repo / 'src/data/hero_presentation_catalog.gd').read_text()
    assert catalog.startswith(old('src/data/hero_presentation_catalog.gd'))
    print(f'Unchanged Hero methods: {len(names) - len(CHANGED)}; Main/Battle, other declarations and prior catalog identical')
    (out / 'src/data').mkdir(parents=True, exist_ok=True)
    (out / 'src/data/hero_presentation_catalog.gd').write_text(catalog)
    header = (repo / 'tests/fixtures/hero_scaled_effect_fixture.gd').read_text()
    for label, source in [('before', before), ('after', after)]:
        text = header
        for line in source.splitlines():
            if re.match(r'^const STAGE1_(?:SHIELD|CHANNEL)_EFFECT_\w+ :=', line):
                text += '\n' + line
        for name in CHANGED + SETUP + (NEW if label == 'after' else []):
            text += '\n\n' + method(source, name)
        (out / (label + '.gd')).write_text(text)
    shutil.copy2(repo / 'tests/hero_scaled_effect_policy_smoke.gd', out / 'smoke.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="ScaledEffectPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
