"""Extract actual slime/common damage/death methods; visuals/popup/authority are spies."""
from pathlib import Path
import argparse,re,shutil
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--slime-baseline',type=Path,required=True);p.add_argument('--common-baseline',type=Path,required=True);a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
def fn(s,n):
 m=re.search(r'^(?:static )?func '+n+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\n(?:static )?func ',tail)
 return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
old=a.slime_baseline.read_text();new=(ROOT/'src/monsters/slime.gd').read_text();co=a.common_baseline.read_text();cn=(ROOT/'src/monsters/monster_runtime_common.gd').read_text()
for name in re.findall(r'^func ([^(]+)\(',old,re.M):
 body=fn(new,name)
 if name=='take_damage':
  body=fn(new,'_apply_slime_damage').replace('func _apply_slime_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:', 'func take_damage(amount: int) -> void:').replace('MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)','MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)').replace('\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n','').replace('_begin_death(receipt, receipt_revision)','_begin_death()')
 if name=='_begin_death':body=body.replace('(receipt = null, receipt_revision: int = 0)','()').replace('collision_shape, &"_on_death_animation_finished", receipt, receipt_revision','collision_shape')
 assert fn(old,name)==body,name
print('Slime original bodies preserved:',len(re.findall(r'^func ',old,re.M)))
for name in re.findall(r'^static func ([^(]+)\(',co,re.M):
 body=fn(cn,name)
 if name=='consume_support_shield':body=fn(cn,'_consume_support_shield').replace('static func _consume_support_shield(owner: Node2D, amount: int, receipt = null, receipt_revision: int = 0) -> int:', 'static func consume_support_shield(owner: Node2D, amount: int) -> int:').replace('\tif receipt != null:\n\t\treceipt.record_shield(absorbed, receipt_revision)\n','')
 if name=='begin_standard_death':body=body.replace('finished_method: StringName = &"_on_death_animation_finished",\n\treceipt = null,\n\treceipt_revision: int = 0','finished_method: StringName = &"_on_death_animation_finished"').replace('\tif receipt != null:\n\t\treceipt.record_death_started(receipt_revision)\n','')
 assert fn(co,name)==body,name
print('Common original bodies preserved:',len(re.findall(r'^static func ',co,re.M)))
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Slime damage receipt fixture"\n')
for path in ['src/systems/battle_damage_receipt.gd','src/systems/battle_entity_registry.gd','tests/slime_receipt_smoke.gd']:
 d=out/path;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,d)
header='''extends CharacterBody2D
const MONSTER_RUNTIME_COMMON = preload("res://tests/common_REPLACE.gd")
const DAMAGE_NUMBERS = preload("res://tests/popups.gd")
signal died
var current_hp := 60
var dying := false
var visual_lod_suspended := false
var hit_flash_timer := 0.0
var visual
var collision_shape = null
var events: Array = []
var hit_callback: Callable
func _visual_call(_method):
    events.append("hit")
    if hit_callback.is_valid():hit_callback.call()
func _on_death_animation_finished():queue_free()
'''
for label,ss,cs in [('before',old,co),('after',new,cn)]:
 methods=['take_damage','_begin_death']+(['supports_damage_receipt','take_damage_with_result','_apply_slime_damage'] if label=='after' else [])
 path=out/('src/monsters/slime.gd' if label=='after' else 'tests/slime_before.gd');path.parent.mkdir(parents=True,exist_ok=True);path.write_text(header.replace('REPLACE',label).replace('    ','\t')+''.join(fn(ss,n) for n in methods))
 common=['consume_support_shield','begin_standard_death']+(['_consume_support_shield'] if label=='after' else [])
 (out/f'tests/common_{label}.gd').write_text('extends RefCounted\nconst DAMAGE_NUMBERS = preload("res://tests/popups.gd")\n'+''.join(fn(cs,n) for n in common))
(out/'tests/popups.gd').write_text('extends RefCounted\nstatic var callback: Callable\nstatic func show(owner,amount):\n\towner.events.append(amount)\n\tif callback.is_valid():callback.call(owner,amount)\n')
(out/'tests/derived.gd').write_text('extends "res://src/monsters/slime.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
