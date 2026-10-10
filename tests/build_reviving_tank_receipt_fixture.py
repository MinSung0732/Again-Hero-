"""Actual Bat/Banshee and Orc/Dullahan inheritance; visual dependencies are spies."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
for n in ['banshee','dullahan','bat','catalog','wolf','scorpion','orc','spider','projectile','wave','slime','common']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_inherited_receipt_fixture.py'),str(out),
    *[v for n in ['wolf','scorpion','orc','spider','projectile','wave','slime','common']
      for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]],check=True)
def fn(s,n):
    m = re.search(r'^func '+re.escape(n)+r'\(',s,re.M);assert m,n
    tail = s[m.start():];end = re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
header = (out/'src/monsters/orc.gd').read_text().split('func take_damage(')[0]
# Inherited fixture callback accepts visual argument arrays, like the real base.
for label,source in [('before',a.bat_baseline.read_text()),('after',(ROOT/'src/monsters/bat.gd').read_text())]:
    methods = ['take_damage','_begin_death']
    if label=='after':methods += ['supports_damage_receipt','take_damage_with_result','_apply_bat_damage']
    path = out/('src/monsters/bat.gd' if label=='after' else 'tests/bat_before.gd')
    path.write_text(header.replace('common_after','common_'+label)+''.join(fn(source,n) for n in methods))
path = out/'src/data/dullahan_behavior_catalog.gd';path.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a.catalog_baseline,path)
for actor in ['banshee','dullahan']:
    old = getattr(a,actor+'_baseline').read_text();new = (ROOT/f'src/monsters/{actor}.gd').read_text()
    names = re.findall(r'^func ([^(]+)\(',old,re.M)
    for name in names:
        body = fn(new,name)
        if name=='take_damage':
            body = fn(new,'_apply_'+actor+'_damage').replace(
                'func _apply_'+actor+'_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:',
                'func take_damage(amount: int) -> void:').replace(
                'MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)',
                'MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)').replace(
                '\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n','').replace(
                '\tif receipt != null:\n\t\treceipt.record_shield(absorbed, receipt_revision)\n\t\treceipt.record_hp(applied, receipt_revision)\n','').replace(
                '\t\tif receipt == null:\n\t\t\t_begin_death()\n\t\telse:\n\t\t\t_begin_death(receipt, receipt_revision)', '\t\t_begin_death()').replace(
                '\t\t\tif receipt == null:\n\t\t\t\t_begin_death()\n\t\t\telse:\n\t\t\t\t_begin_death_with_result(receipt, receipt_revision)', '\t\t\t_begin_death()')
        assert body==fn(old,name),(actor,name)
    print(actor,'original bodies preserved:',len(names))
    for label,source in [('before',old),('after',new)]:
        parent = 'bat' if actor=='banshee' else 'orc'
        parent_path = f'src/monsters/{parent}.gd' if label=='after' else f'tests/{parent}_before.gd'
        content = f'extends "res://{parent_path}"\n'
        methods = ['take_damage']
        if actor=='dullahan':
            content += '''const BEHAVIOR = preload("res://src/data/dullahan_behavior_catalog.gd")
const PASSIVE: Dictionary = BEHAVIOR.PASSIVE
var shield_hp := 0
var wall_max_hp := 0
var revive_used := false
var reviving := false
var revive_reverse_started := false
var march_remaining := 0
var danger_state := 0
var slam_state := 0
var slam_target: Node2D
var slam_config: Dictionary = {}
var attack_damage := 13
var attack_range := 100.0
var visual_moving_state := -1
var unexpected_slam_hits := 0
func _deal_hit(_target,_amount,_stun):unexpected_slam_hits += 1
'''
            methods += ['_sync_wall_capacity','_cancel_slam','_finish_slam','_tick_revival','_complete_revival']
        if label=='after':methods += ['supports_damage_receipt','take_damage_with_result','_apply_'+actor+'_damage']
        path = out/(f'src/monsters/{actor}.gd' if label=='after' else f'tests/{actor}_before.gd')
        path.write_text(content+''.join(fn(source,n) for n in methods))
    (out/f'tests/{actor}_derived.gd').write_text(f'extends "res://src/monsters/{actor}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    smoke = (out/'tests/orc_receipt_smoke.gd').read_text().replace('orc_before',actor+'_before').replace(
        'src/monsters/orc.gd',f'src/monsters/{actor}.gd').replace('orc_derived',actor+'_derived').replace(
        'orc receipt',actor+' receipt')
    wave = (out/'tests/orc_wave_receipt_smoke.gd').read_text().replace('src/monsters/orc.gd',f'src/monsters/{actor}.gd')
    if actor=='dullahan':
        smoke = smoke.replace('class Visual extends Node:', 'class Visual extends Node2D:').replace('signal death_animation_finished','signal death_animation_finished\n\tsignal animation_finished').replace(
            '\ta.current_hp = hp','\ta.current_hp = hp\n\tif a.has_method("_tick_revival"):\n\t\ta.revive_used = true\n\t\ta.collision_shape = CollisionShape2D.new()\n\t\ta.add_child(a.collision_shape)')
        wave = wave.replace('class Visual extends Node:', 'class Visual extends Node2D:').replace('signal death_animation_finished','signal death_animation_finished\n\tsignal animation_finished').replace(
            '\ta.current_hp = hp','\ta.current_hp = hp\n\tif a.has_method("_tick_revival"):\n\t\ta.revive_used = true\n\t\ta.collision_shape = CollisionShape2D.new()\n\t\ta.add_child(a.collision_shape)')
    (out/f'tests/{actor}_receipt_smoke.gd').write_text(smoke)
    (out/f'tests/{actor}_wave_receipt_smoke.gd').write_text(wave)
    (out/f'tests/{actor}_wave_helper.gd').write_text(wave.replace('extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
shutil.copy2(ROOT/'tests/reviving_tank_receipt_smoke.gd',out/'tests/reviving_tank_receipt_smoke.gd')
