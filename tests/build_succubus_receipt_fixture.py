"""Actual Succubus/Orc damage, infiltration, healing and wave slices."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
for n in ['succubus', 'catalog', 'policy', 'wolf', 'scorpion', 'orc', 'spider', 'projectile', 'wave', 'slime', 'common']:
    p.add_argument('--'+n+'-baseline', type=Path, required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable, str(ROOT/'tests/build_inherited_receipt_fixture.py'), str(out),
    *[v for n in ['wolf','scorpion','orc','spider','projectile','wave','slime','common']
      for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]], check=True)

def fn(s,n):
    m = re.search(r'^(?:static )?func '+re.escape(n)+r'\(',s,re.M)
    assert m,n
    tail = s[m.start():]
    end = re.search(r'\n(?:static )?func ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'

old = a.succubus_baseline.read_text()
new = (ROOT/'src/monsters/succubus.gd').read_text()
names = re.findall(r'^func ([^(]+)\(',old,re.M)
for name in names:
    body = fn(new,name)
    if name == 'take_damage':
        body = fn(new,'_apply_succubus_damage').replace(
            'func _apply_succubus_damage(amount: int, receipt = null, receipt_revision: int = 0)',
            'func take_damage(amount: int)').replace(
            'MONSTER_RUNTIME_COMMON._consume_support_shield(self, amount, receipt, receipt_revision)',
            'MONSTER_RUNTIME_COMMON.consume_support_shield(self, amount)').replace(
            '\t# Record before popup callbacks and infiltration\'s optional recovery.\n\tif receipt != null:\n\t\treceipt.record_hp(previous_hp - current_hp, receipt_revision)\n','').replace(
            '\t\tif receipt == null:\n\t\t\t_begin_death()\n\t\telse:\n\t\t\t_begin_death_with_result(receipt, receipt_revision)',
            '\t\t_begin_death()')
    if name == '_begin_death':
        body = fn(new,'_begin_succubus_death').replace(
            'func _begin_succubus_death(receipt = null, receipt_revision: int = 0)',
            'func _begin_death()').replace(
            'super._begin_death_with_result(receipt, receipt_revision)', 'super._begin_death()')
    assert body == fn(old,name),name
print('Succubus original bodies preserved:',len(names))
for label in ['before','after']:
    path = out/('src/monsters/orc.gd' if label=='after' else 'tests/orc_before.gd')
    path.write_text(path.read_text()+fn((ROOT/'src/monsters/orc.gd').read_text(),'heal_direct'))
    path = out/f'tests/common_{label}.gd'
    path.write_text(path.read_text()+fn((ROOT/'src/monsters/monster_runtime_common.gd').read_text(),'apply_direct_heal'))
path = out/'tests/popups.gd'
path.write_text(path.read_text()+'''static var heal_callback: Callable
static func show_heal(owner,amount):
\towner.events.append(["heal",amount])
\tif heal_callback.is_valid():heal_callback.call(owner,amount)
''')
for source,target in [(a.catalog_baseline,'src/data/succubus_behavior_catalog.gd'),
                      (a.policy_baseline,'src/systems/hero_target_policy.gd')]:
    path = out/target
    path.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,path)
fields = '''const BEHAVIOR = preload("res://src/data/succubus_behavior_catalog.gd")
const HERO_TARGET_POLICY = preload("res://src/systems/hero_target_policy.gd")
const EMPTY_CONFIG: Dictionary = {}
var infiltration_used := false
var infiltration_timer := 0.0
var infiltration_finished := false
var infiltration_collision_layer := 0
var infiltration_collision_mask := 0
var infiltration_shape_disabled := false
var infiltration_ignore_separation := false
var waltz_active := false
var waltz_config: Dictionary = {}
var visual_moving_state := 0
'''
for label,source in [('before',old),('after',new)]:
    parent = 'src/monsters/orc.gd' if label=='after' else 'tests/orc_before.gd'
    methods = ['take_damage','_start_infiltration','_tick_infiltration','_cancel_waltz','_begin_death']
    if label=='after':
        methods += ['supports_damage_receipt','take_damage_with_result','_apply_succubus_damage',
                    '_begin_death_with_result','_begin_succubus_death']
    path = out/('src/monsters/succubus.gd' if label=='after' else 'tests/succubus_before.gd')
    path.write_text(f'extends "res://{parent}"\n'+fields+''.join(fn(source,n) for n in methods))
(out/'tests/succubus_derived.gd').write_text(
    'extends "res://src/monsters/succubus.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
smoke = (out/'tests/orc_receipt_smoke.gd').read_text().replace(
    'orc_before','succubus_before').replace('src/monsters/orc.gd','src/monsters/succubus.gd').replace(
    'orc_derived','succubus_derived').replace('orc receipt','Succubus receipt')
wave = (out/'tests/orc_wave_receipt_smoke.gd').read_text().replace(
    'src/monsters/orc.gd','src/monsters/succubus.gd')
for label,source in [('succubus_receipt',smoke),('succubus_wave_receipt',wave)]:
    source = source.replace('class Visual extends Node:', 'class Visual extends Node2D:').replace(
        '\tfunc play_death():owner_actor.events.append("death")',
        '\tfunc play_death():owner_actor.events.append("death")\n\tfunc play_locomotion(_moving):owner_actor.events.append("idle")')
    source = source.replace('\ta.current_hp = hp','''\ta.infiltration_used = true
\tvar shape = CollisionShape2D.new()
\ta.add_child(shape)
\ta.collision_shape = shape
\ta.current_hp = hp''')
    if label=='succubus_wave_receipt':
        source = source.replace('extends SceneTree','extends SceneTree\nconst POPUPS = preload("res://tests/popups.gd")')
    actor = 'fresh' if label=='succubus_receipt' else 'w.a'
    source = source.replace(f'{actor}.hit_callback = func():{actor}.dying = true',
        f'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\t{actor}.dying = true')
    if label=='succubus_wave_receipt':
        source = source.replace('w.a.hit_callback = func():\n\t\tw.a.hit_callback = Callable()',
            'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()')
    (out/f'tests/{label}_smoke.gd').write_text(source)
    (out/f'tests/{label}_helper.gd').write_text(source.replace(
        'extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
shutil.copy2(ROOT/'tests/succubus_receipt_special_smoke.gd',out/'tests/succubus_receipt_special_smoke.gd')
