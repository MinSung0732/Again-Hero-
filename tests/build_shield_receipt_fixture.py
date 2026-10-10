"""Build actual Bat/Ghost/Mummy damage slices and preserve all original bodies.

Visuals, scene initialization and target authority are spies. Mummy counterattack,
shield rescaling and inherited Orc death are actual extracted functions.
"""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('target', type=Path)
for name in ['bat', 'ghost', 'mummy', 'projectile', 'wave', 'slime', 'common',
             'status-scope', 'mummy-catalog']:
    parser.add_argument('--'+name+'-baseline', type=Path, required=True)
args = parser.parse_args()
out = args.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([
    sys.executable, str(ROOT/'tests/build_wave_receipt_fixture.py'), str(out),
    *[value for name in ['projectile', 'wave', 'slime', 'common']
      for value in ['--'+name+'-baseline', str(getattr(args, name+'_baseline'))]]
], check=True)


def function(source, name):
    match = re.search(r'^(?:static )?func '+re.escape(name)+r'\(', source, re.M)
    assert match, name
    tail = source[match.start():]
    end = re.search(r'\n(?:static )?func ', tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'


common = (ROOT/'src/monsters/monster_runtime_common.gd').read_text()
for label in ['before', 'after']:
    p = out/f'tests/common_{label}.gd'
    p.write_text(p.read_text()+function(common, 'resolve_combat_target'))
for name, source in [('src/systems/status_action_scope.gd', args.status_scope_baseline),
                     ('src/data/mummy_behavior_catalog.gd', args.mummy_catalog_baseline)]:
    p = out/name
    p.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, p)

header = (out/'src/monsters/slime.gd').read_text().split('func take_damage(')[0]
header = header.replace('var visual\n', 'var visual: Node2D\n')
header += '''var max_hp := 60
var special_augment_configs: Dictionary = {}
var combat_authority: Node
var hero: Node2D
'''
for actor in ['bat', 'ghost', 'mummy']:
    old = getattr(args, actor+'_baseline').read_text()
    new = (ROOT/f'src/monsters/{actor}.gd').read_text()
    names = re.findall(r'^func ([^(]+)\(', old, re.M)
    for name in names:
        body = function(new, name)
        if name == 'take_damage':
            body = function(new, '_apply_'+actor+'_damage').replace(
                f'func _apply_{actor}_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:',
                'func take_damage(amount: int) -> void:').replace(
                'MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)',
                'MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)').replace(
                '\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n', '').replace(
                '\tif receipt != null:\n\t\treceipt.record_hp(previous_hp - current_hp, receipt_revision)\n', '').replace(
                '\tif receipt != null:\n\t\treceipt.record_shield(absorbed, receipt_revision)\n\t\treceipt.record_hp(health_damage, receipt_revision)\n', '').replace(
                '_begin_death(receipt, receipt_revision)', '_begin_death()').replace(
                '\t\tif receipt == null:\n\t\t\t_begin_death()\n\t\telse:\n\t\t\t_begin_death_with_result(receipt, receipt_revision)', '\t\t_begin_death()')
        if name == '_begin_death':
            body = body.replace('(receipt = null, receipt_revision: int = 0)', '()').replace(
                'collision_shape,\n\t\t&"_on_death_animation_finished",\n\t\treceipt,\n\t\treceipt_revision', 'collision_shape')
        assert body == function(old, name), (actor, name)
    print(actor, 'original bodies preserved:', len(names))
    actor_header = header
    if actor == 'ghost':
        actor_header += 'var phase_shift_active := false\n'
    if actor == 'mummy':
        actor_header += '''const BEHAVIOR = preload("res://src/data/mummy_behavior_catalog.gd")
const STATUS_SCOPE = preload("res://src/systems/status_action_scope.gd")
var shield_hp := 0
var shield_capacity := 0
var shield_basis_hp := 60
var shield_broken := false
var elite_curse: Dictionary = {}
'''
    for label, source in [('before', old), ('after', new)]:
        methods = ['take_damage']
        if actor != 'mummy':
            methods += ['_begin_death']
        else:
            methods += ['_sync_shield_capacity', '_deal_damage', '_status_scoped_deal_damage']
        if label == 'after':
            methods += ['supports_damage_receipt', 'take_damage_with_result', '_apply_'+actor+'_damage']
        content = actor_header.replace('common_after', 'common_'+label)
        content += ''.join(function(source, method) for method in methods)
        if actor == 'mummy':
            # Mummy uses its real inherited Orc death method; no Orc rage damage.
            parent = (ROOT/'src/monsters/orc.gd').read_text()
            if label == 'before':
                death = function(parent, '_begin_orc_standard_death').replace(
                    'func _begin_orc_standard_death(receipt = null, receipt_revision: int = 0)', 'func _begin_death()').replace(
                    'collision_shape,\n\t\t&"_on_death_animation_finished",\n\t\treceipt,\n\t\treceipt_revision', 'collision_shape')
            else:
                death = ''.join(function(parent,n) for n in ['_begin_death','_begin_death_with_result','_begin_orc_standard_death'])
            content += death
        p = out/(f'src/monsters/{actor}.gd' if label == 'after' else f'tests/{actor}_before.gd')
        p.write_text(content)
    (out/f'tests/{actor}_derived.gd').write_text(
        f'extends "res://src/monsters/{actor}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    smoke = (ROOT/'tests/slime_receipt_smoke.gd').read_text().replace(
        'slime_before', actor+'_before').replace('src/monsters/slime.gd', f'src/monsters/{actor}.gd').replace(
        'tests/derived.gd', f'tests/{actor}_derived.gd').replace('Slime receipt', actor+' receipt').replace(
        'class Visual extends Node:', 'class Visual extends Node2D:')
    wave = (ROOT/'tests/wave_receipt_smoke.gd').read_text().replace(
        'src/monsters/slime.gd', f'src/monsters/{actor}.gd').replace(
        'class Visual extends Node:', 'class Visual extends Node2D:')
    if actor == 'ghost':
        # Lethal Ghost does not play hit; use its actual popup callback boundary.
        smoke = smoke.replace('fresh.hit_callback = func():fresh.dying = true',
                              'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\tfresh.dying = true')
        wave = wave.replace('extends SceneTree', 'extends SceneTree\nconst POPUPS := preload("res://tests/popups.gd")').replace(
            'w.a.hit_callback = func():w.a.dying = true',
            'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\tw.a.dying = true').replace(
            'w.a.hit_callback = func():\n\t\tw.a.hit_callback = Callable()',
            'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()')
    (out/f'tests/{actor}_receipt_smoke.gd').write_text(smoke)
    (out/f'tests/{actor}_wave_receipt_smoke.gd').write_text(wave)
    (out/f'tests/{actor}_wave_helper.gd').write_text(
        wave.replace('extends SceneTree', 'extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
shutil.copy2(ROOT/'tests/mummy_shield_receipt_smoke.gd', out/'tests/mummy_shield_receipt_smoke.gd')
