"""Verify exact original actor bodies and exercise real damage/wave slices.

Baseline files must be fetched at the documented pre-change commit. Visuals and
authority are spies; this fixture does not emulate complete monster AI/physics.
"""
from pathlib import Path
import argparse
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
for name in ['spider', 'orc', 'projectile', 'wave', 'slime', 'common']:
    p.add_argument('--'+name+'-baseline', type=Path, required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([
    sys.executable, str(ROOT/'tests/build_wave_receipt_fixture.py'), str(out),
    *[v for name in ['projectile', 'wave', 'slime', 'common']
      for v in ['--'+name+'-baseline', str(getattr(a, name+'_baseline'))]]
], check=True)


def fn(source, name):
    m = re.search(r'^func '+re.escape(name)+r'\(', source, re.M)
    assert m, name
    tail = source[m.start():]
    end = re.search(r'\nfunc ', tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'


header = (out/'src/monsters/slime.gd').read_text().split('func take_damage(')[0]
# Both sides have the same fixture-only state; actual Orc methods are extracted.
header += '''var max_hp := 60
var special_augment_configs: Dictionary = {}
var rage_stacks := 0
var last_charge_triggered := false
var last_charge_timer := 0.0
'''
for name in ['spider', 'orc']:
    old = getattr(a, name+'_baseline').read_text()
    new = (ROOT/f'src/monsters/{name}.gd').read_text()
    names = re.findall(r'^func ([^(]+)\(', old, re.M)
    for method in names:
        body = fn(new, method)
        if method == 'take_damage':
            body = fn(new, '_apply_'+name+'_damage').replace(
                f'func _apply_{name}_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:',
                'func take_damage(amount: int) -> void:').replace(
                'MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)',
                'MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)').replace(
                '\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n', '').replace(
                '_begin_death(receipt, receipt_revision)', '_begin_death()').replace('_begin_death_with_result(receipt, receipt_revision)', '_begin_death()')
        body = body.replace('\t\t# Legacy derived actors keep their zero-argument death override.\n\t\tif receipt == null:\n\t\t\t_begin_death()\n\t\telse:\n\t\t\t_begin_death()', '\t\t_begin_death()')
        if method == '_begin_death':
            if name == 'orc':
                body = fn(new, '_begin_orc_standard_death').replace('func _begin_orc_standard_death', 'func _begin_death')
            body = body.replace('(receipt = null, receipt_revision: int = 0)', '()').replace(
                'collision_shape, &"_on_death_animation_finished", receipt, receipt_revision', 'collision_shape').replace(
                'collision_shape,\n\t\t&"_on_death_animation_finished",\n\t\treceipt,\n\t\treceipt_revision', 'collision_shape')
        assert body == fn(old, method), (name, method)
    print(name, 'original bodies preserved:', len(names))
    for label, source in [('before', old), ('after', new)]:
        methods = ['take_damage', '_begin_death']
        if label == 'after':
            methods += ['supports_damage_receipt', 'take_damage_with_result', '_apply_'+name+'_damage']
            if name == 'orc':methods += ['_begin_death_with_result','_begin_orc_standard_death']
        if name == 'orc':
            methods += ['_add_rage_stack', '_try_trigger_last_charge']
        path = out/(f'src/monsters/{name}.gd' if label == 'after' else f'tests/{name}_before.gd')
        path.write_text(header.replace('common_after', 'common_'+label)+''.join(fn(source, n) for n in methods))
    (out/f'tests/{name}_derived.gd').write_text(
        f'extends "res://src/monsters/{name}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    # Run all receipt boundary and wave integration cases against each actor.
    smoke = (ROOT/'tests/slime_receipt_smoke.gd').read_text().replace('slime_before', name+'_before').replace(
        'src/monsters/slime.gd', f'src/monsters/{name}.gd').replace(
        'tests/derived.gd', f'tests/{name}_derived.gd').replace('Slime receipt', name+' receipt')
    (out/f'tests/{name}_receipt_smoke.gd').write_text(smoke)
    wave = (ROOT/'tests/wave_receipt_smoke.gd').read_text().replace(
        'src/monsters/slime.gd', f'src/monsters/{name}.gd')
    (out/f'tests/{name}_wave_receipt_smoke.gd').write_text(wave)
(out/'tests/orc_receipt_augment_smoke.gd').write_text((ROOT/'tests/orc_receipt_augment_smoke.gd').read_text())
