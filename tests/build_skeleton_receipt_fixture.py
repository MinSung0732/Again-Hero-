"""Extract actual skeleton damage/revival/death functions; rendering is a spy."""
from pathlib import Path
import argparse,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path)
for n in ['skeleton','projectile','wave','slime','common']:p.add_argument('--'+n+'-baseline',type=Path,required=True)
a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_wave_receipt_fixture.py'),str(out),*[v for n in ['projectile','wave','slime','common'] for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]],check=True)
def fn(source,name):
    m=re.search(r'^(?:static )?func '+re.escape(name)+r'\(',source,re.M);assert m,name
    tail=source[m.start():];end=re.search(r'\n(?:static )?func ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
old=a.skeleton_baseline.read_text();new=(ROOT/'src/monsters/skeleton.gd').read_text()
names=re.findall(r'^func ([^(]+)\(',old,re.M)
for name in names:
    body=fn(new,name)
    if name=='take_damage':
        body=fn(new,'_apply_skeleton_damage').replace('func _apply_skeleton_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:','func take_damage(amount: int) -> void:').replace('MONSTER_RUNTIME_COMMON._consume_support_shield(self,reduced_damage,receipt,receipt_revision)','MONSTER_RUNTIME_COMMON.consume_support_shield(self,reduced_damage)').replace('\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n','').replace('_begin_death(receipt, receipt_revision)','_begin_death()')
    if name=='_begin_death':body=body.replace('(receipt = null, receipt_revision: int = 0)','()').replace('collision_shape,\n\t\t&"_on_death_animation_finished",\n\t\treceipt,\n\t\treceipt_revision','collision_shape')
    assert body==fn(old,name),name
print('Skeleton original bodies preserved:',len(names))
header=(out/'src/monsters/slime.gd').read_text().split('func take_damage(')[0].replace('func _visual_call(_method):','func _visual_call(_method, _args: Array = []):')
header=header.replace('var visual\n','var visual: Node2D\n')
header+='''var max_hp := 60
var special_augment_configs: Dictionary = {}
var combat_authority: Node
var reviving := false
var revive_used := false
var revive_timer := 0.0
var revive_reverse_started := false
var pending_second_hit_timer := -1.0
var pending_second_hit_target = null
'''
for label,source in [('before',old),('after',new)]:
    methods=['take_damage','_begin_death','_can_revive','_begin_revival','_tick_revival','_complete_revival','_break_ambush','_notify_elite_alive','heal_direct']
    if label=='after':methods+=['supports_damage_receipt','take_damage_with_result','_apply_skeleton_damage']
    path=out/('src/monsters/skeleton.gd' if label=='after' else 'tests/skeleton_before.gd')
    path.write_text(header.replace('common_after','common_'+label)+''.join(fn(source,n) for n in methods))
    common=out/f'tests/common_{label}.gd';common.write_text(common.read_text()+fn((ROOT/'src/monsters/monster_runtime_common.gd').read_text(),'apply_direct_heal'))
(out/'tests/popups.gd').write_text((out/'tests/popups.gd').read_text()+'static func show_heal(owner,amount):owner.events.append(amount)\n')
(out/'tests/skeleton_derived.gd').write_text('extends "res://src/monsters/skeleton.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
smoke=(ROOT/'tests/slime_receipt_smoke.gd').read_text().replace('slime_before','skeleton_before').replace('src/monsters/slime.gd','src/monsters/skeleton.gd').replace('tests/derived.gd','tests/skeleton_derived.gd').replace('Slime receipt','Skeleton receipt').replace('class Visual extends Node:','class Visual extends Node2D:')
smoke=smoke.replace('\tvar aura := 1.0','\tvar elite_living := false\n\tfunc has_living_elite_skeleton():return elite_living\n\tfunc set_elite_skeleton_alive(a,alive):\n\t\telite_living = alive\n\t\ta.events.append(alive)\n\tvar aura := 1.0').replace('\ta.current_hp = hp','\ta.combat_authority = scope\n\ta.current_hp = hp')
# Skeleton does not play hit visual on a lethal hit; use its real popup boundary.
smoke=smoke.replace('fresh.hit_callback = func():fresh.dying = true','POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\tfresh.dying = true')
(out/'tests/skeleton_receipt_smoke.gd').write_text(smoke)
wave=(ROOT/'tests/wave_receipt_smoke.gd').read_text().replace('src/monsters/slime.gd','src/monsters/skeleton.gd').replace('class Visual extends Node:','class Visual extends Node2D:')
wave=wave.replace('extends SceneTree','extends SceneTree\nconst POPUPS := preload("res://tests/popups.gd")').replace('w.a.hit_callback = func():w.a.dying = true','POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\tw.a.dying = true').replace('w.a.hit_callback = func():\n\t\tw.a.hit_callback = Callable()','POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()')
(out/'tests/skeleton_wave_receipt_smoke.gd').write_text(wave)
(out/'tests/skeleton_wave_helper.gd').write_text(wave.replace('extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
(out/'tests/skeleton_revival_smoke.gd').write_text((ROOT/'tests/skeleton_revival_smoke.gd').read_text())
