"""Actual goblin/bomb-rat damage/death slices; rendering/explosion execution are spies."""
from pathlib import Path
import argparse,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path)
for n in ['goblin','bomb-rat','projectile','wave','slime','common']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_wave_receipt_fixture.py'),str(out),*[v for n in ['projectile','wave','slime','common'] for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]],check=True)
def fn(source,name):
    m=re.search(r'^func '+re.escape(name)+r'\(',source,re.M);assert m,name
    tail=source[m.start():];end=re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
header=(out/'src/monsters/slime.gd').read_text().split('func take_damage(')[0]
header+='''var max_hp := 60
var stealth_remaining := 0.0
var stealth_damage_multiplier := 0.5
var self_destructing := false
var self_destruct_hp_ratio := 1.0
var exp_reward := 30
var hero_kill_exp_reward := 30
var self_destruct_exp_reward := 10
var warning_layer: Node2D
var hit_flash_material = null
func _ensure_hit_flash_material():
\tevents.append("flash")
\tif hit_callback.is_valid():hit_callback.call()
func _resume_visual_from_lod():events.append("resume")
func _restart_visual_animation(animation):events.append(animation)
func _play_death_or_free():events.append("death")
func _play_explosion_effect():events.append("explosion_fx")
func _trigger_death_explosion():events.append("explosion_damage")
'''
for name in ['goblin','bomb_rat']:
    old=getattr(a,name+'_baseline').read_text();new=(ROOT/f'src/monsters/{name}.gd').read_text()
    names=re.findall(r'^func ([^(]+)\(',old,re.M)
    for method in names:
        body=fn(new,method)
        if method=='take_damage':
            body=fn(new,'_apply_'+name+'_damage').replace(f'func _apply_{name}_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:','func take_damage(amount: int) -> void:').replace('MONSTER_RUNTIME_COMMON._consume_support_shield(self,remaining_damage,receipt,receipt_revision)','MONSTER_RUNTIME_COMMON.consume_support_shield(self,remaining_damage)').replace('\t\tif receipt != null:\n\t\t\treceipt.record_shield(absorbed, receipt_revision)\n','').replace('\tif receipt != null:\n\t\treceipt.record_hp(previous_hp - current_hp, receipt_revision)\n','').replace('\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n','').replace('_begin_death(receipt, receipt_revision)','_begin_death()').replace('_die_from_hero(receipt, receipt_revision)','_die_from_hero()')
        if method in ['_begin_death','_die_from_hero']:
            body=body.replace('(receipt = null, receipt_revision: int = 0)','()').replace('collision_shape, &"_on_death_animation_finished", receipt, receipt_revision','collision_shape').replace('\tif receipt != null:\n\t\treceipt.record_death_started(receipt_revision)\n','')
        assert body==fn(old,method),(name,method)
    print(name,'original bodies preserved:',len(names))
    for label,source in [('before',old),('after',new)]:
        methods=['take_damage']+(['_begin_death'] if name=='goblin' else ['_die_from_hero','_complete_self_destruct'])
        if label=='after':methods+=['supports_damage_receipt','take_damage_with_result','_apply_'+name+'_damage']
        path=out/(f'src/monsters/{name}.gd' if label=='after' else f'tests/{name}_before.gd')
        path.write_text(header.replace('common_after','common_'+label)+''.join(fn(source,n) for n in methods))
    (out/f'tests/{name}_derived.gd').write_text(f'extends "res://src/monsters/{name}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    smoke=(ROOT/'tests/slime_receipt_smoke.gd').read_text().replace('slime_before',name+'_before').replace('src/monsters/slime.gd',f'src/monsters/{name}.gd').replace('tests/derived.gd',f'tests/{name}_derived.gd').replace('Slime receipt',name+' receipt')
    # Bomb-rat's real death code requires its warning/collision children.
    smoke=smoke.replace('\ta.current_hp = hp','\ta.warning_layer = Node2D.new()\n\ta.add_child(a.warning_layer)\n\ta.collision_shape = CollisionShape2D.new()\n\ta.add_child(a.collision_shape)\n\ta.current_hp = hp')
    (out/f'tests/{name}_receipt_smoke.gd').write_text(smoke)
    wave=(ROOT/'tests/wave_receipt_smoke.gd').read_text().replace('src/monsters/slime.gd',f'src/monsters/{name}.gd').replace('\ta.position = Vector2(100,0)','\ta.warning_layer = Node2D.new()\n\ta.add_child(a.warning_layer)\n\ta.collision_shape = CollisionShape2D.new()\n\ta.add_child(a.collision_shape)\n\ta.position = Vector2(100,0)')
    (out/f'tests/{name}_wave_receipt_smoke.gd').write_text(wave)
(out/'tests/goblin_bomb_special_smoke.gd').write_text((ROOT/'tests/goblin_bomb_special_smoke.gd').read_text())
