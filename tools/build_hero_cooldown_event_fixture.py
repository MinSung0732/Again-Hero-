"""Compare actual cooldown owners and death/level-up event dispatch."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
from build_hero_combat_effect_fixture import method

CHANGED = ['_get_external_skill_cooldown_properties', 'add_random_skill_cooldown_delay',
           '_tick_fear_skill_cooldowns', 'impose_all_skill_cooldowns',
           '_begin_death_sequence', '_play_level_up_feedback']
NEW = ['_get_skill_cooldown_bindings', '_play_bound_hero_audio']


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
        source = re.sub(r'^const HERO_RUNTIME_BINDINGS := .*\n', '', source, flags=re.M)
        source = re.sub(r'^const ARCHMAGE_SKILL_KEYS: Array\[String\] = \[.*?^\]\n', '', source, flags=re.M | re.S)
        source = re.sub(r'^const ARCHMAGE_SKILL_KEYS: Array\[String\] = .*\n', '', source, flags=re.M)
        return ''.join(source.split())
    assert outer(before) == outer(after), 'Unexpected Hero declarations changed'
    for path in ['src/main/main.gd', 'src/battle/battle.gd']:
        assert old(path) == (repo / path).read_text(), path
    catalog = (repo / 'src/data/hero_presentation_catalog.gd').read_text()
    assert catalog.startswith(old('src/data/hero_presentation_catalog.gd'))
    print(f'Unchanged Hero methods: {len(names) - len(CHANGED)}; Main/Battle and prior presentation data identical')
    (out / 'src/data').mkdir(parents=True, exist_ok=True)
    (out / 'src/data/hero_presentation_catalog.gd').write_text(catalog)
    shutil.copy2(repo / 'src/data/hero_runtime_binding_catalog.gd', out / 'src/data/hero_runtime_binding_catalog.gd')
    header = (repo / 'tests/fixtures/hero_cooldown_event_fixture.gd').read_text()
    for label, source in [('before', before), ('after', after)]:
        text = header
        if label == 'before':
            text += '\n' + re.search(r'^const ARCHMAGE_SKILL_KEYS: Array\[String\] = \[.*?^\]', source, re.M | re.S).group() + '\n'
        else:
            text += '\nconst ARCHMAGE_SKILL_KEYS: Array[String] = HERO_RUNTIME_BINDINGS.ARCHMAGE_SKILL_KEYS\n'
        for name in CHANGED + ['_clear_charm'] + (NEW if label == 'after' else []):
            text += '\n' + method(source, name)
        (out / (label + '.gd')).write_text(text)
    shutil.copy2(repo / 'tests/hero_cooldown_event_policy_smoke.gd', out / 'smoke.gd')
    shutil.copy2(repo / 'tests/hero_cooldown_policy_benchmark.gd', out / 'benchmark.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="CooldownEventFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
