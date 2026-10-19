"""Extract real stack/roll/application owners and compare against a git baseline."""
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

    hero_path = 'src/hero/hero.gd'
    catalog_path = 'src/data/hero_augment_catalog.gd'
    before, after = old(hero_path), (repo / hero_path).read_text()
    changed = '_get_augment_roll_build_counts'
    names = re.findall(r'^func (\w+)\(', before, re.M)
    assert re.findall(r'^func (\w+)\(', after, re.M) == names
    for name in names:
        if name != changed:
            assert method(before, name) == method(after, name), name
    assert before.replace(method(before, changed), '') == after.replace(method(after, changed), '')
    old_catalog = old(catalog_path)
    catalog = (repo / catalog_path).read_text()
    # Every existing function except the effective limit getter stays exact.
    for name in re.findall(r'^static func (\w+)\(', old_catalog, re.M):
        if name != 'get_effective_max_stack':
            assert method(old_catalog.replace('static func ', 'func '), name) == method(catalog.replace('static func ', 'func '), name), name
    assert old_catalog[old_catalog.index('const AUGMENTS ='):old_catalog.index('static func get_effective_max_stack')] == catalog[catalog.index('const AUGMENTS ='):catalog.index('static func get_effective_max_stack')]
    for path in ['src/main/main.gd', 'src/battle/battle.gd', 'src/data/hero_codex_catalog.gd', 'src/data/hero_profiles.gd']:
        assert old(path) == (repo / path).read_text(), path
    print(f'Unchanged Hero methods: {len(names)-1}; original augment data/roll algorithm/application/UI/Battle identical')

    header = '''extends RefCounted
const AUGMENT_CATALOG = preload("res://CATALOG.gd")
var hero_archetype: String = ""
var build_counts: Dictionary = {}
var effects: Array = []
var hooks: Array = []
func _apply_augment_effect(effect: Dictionary) -> void: effects.append(effect.duplicate(true))
func _dispatch_augment_stack_hook(id: String) -> void: hooks.append(id)
'''
    owners = [changed, '_get_effective_augment_max_stack', '_apply_augment']
    for label, source, data in [('before', before, old_catalog), ('after', after, catalog)]:
        (out / (label + '_catalog.gd')).write_text(data.replace('class_name HeroAugmentCatalog\n', ''))
        actor = header.replace('res://CATALOG.gd', 'res://' + label + '_catalog.gd')
        (out / (label + '.gd')).write_text(actor + '\n'.join(method(source, name) for name in owners))
    # A content-only extension proves that no runtime hero/augment switch is needed.
    extension = catalog.replace('"alchemist_chemical": {"pursuit": 3},',
                                '"alchemist_chemical": {"pursuit": 3},\n\t"fixture_new_hero": {"pursuit": 1, "projectile_power": 2},')
    assert extension != catalog
    (out / 'extended_catalog.gd').write_text(extension.replace('class_name HeroAugmentCatalog\n', ''))
    (out / 'extended.gd').write_text(header.replace('res://CATALOG.gd', 'res://extended_catalog.gd') + '\n'.join(method(after, name) for name in owners))
    shutil.copy2(repo / 'tests/hero_stack_policy_smoke.gd', out / 'smoke.gd')
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="HeroStackPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')


if __name__ == '__main__':
    main()
