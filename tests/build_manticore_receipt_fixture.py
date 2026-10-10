"""Actual Manticore/Thrower damage, first escape, track and death slices."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target',type=Path)
for n in ['manticore','catalog','wolf','scorpion','orc','spider','projectile','wave','slime','common']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_inherited_receipt_fixture.py'),str(out),
    *[v for n in ['wolf','scorpion','orc','spider','projectile','wave','slime','common']
      for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]],check=True)
def fn(s,n):
    m = re.search(r'^func '+re.escape(n)+r'\(',s,re.M)
    assert m,n
    tail = s[m.start():]
    end = re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
old = a.manticore_baseline.read_text()
new = (ROOT/'src/monsters/manticore.gd').read_text()
names = re.findall(r'^func ([^(]+)\(',old,re.M)
for name in names:
    body = fn(new,name)
    if name=='take_damage':
        body = fn(new,'_apply_manticore_damage').replace(
            'func _apply_manticore_damage(amount: int, receipt = null, receipt_revision: int = 0)',
            'func take_damage(amount: int)').replace(
            'MONSTER_RUNTIME_COMMON._consume_support_shield(self,int(round(amount*(0.6 if guard_remaining > 0.0 else 1.0))),receipt,receipt_revision)',
            'MONSTER_RUNTIME_COMMON.consume_support_shield(self,int(round(amount*(0.6 if guard_remaining > 0.0 else 1.0))))').replace(
            '\t\tvar escape_previous_hp := current_hp\n','').replace(
            '\t\t# Immediate recovery may increase HP; record only the actual decrease.\n\t\tif receipt != null:\n\t\t\treceipt.record_hp(maxi(escape_previous_hp-current_hp,0), receipt_revision)\n','').replace(
            '\tvar previous_hp := current_hp\n','').replace(
            '\tif receipt != null:\n\t\treceipt.record_hp(maxi(previous_hp-current_hp,0), receipt_revision)\n','').replace(
            '\tif current_hp <= 0:\n\t\tif receipt == null:\n\t\t\t_begin_death()\n\t\telse:\n\t\t\t_begin_death_with_result(receipt, receipt_revision)',
            '\tif current_hp <= 0: _begin_death()')
    if name=='_begin_death':
        body = fn(new,'_begin_manticore_death').replace(
            'func _begin_manticore_death(receipt = null, receipt_revision: int = 0)',
            'func _begin_death()').replace(
            'super._begin_death_with_result(receipt, receipt_revision)','super._begin_death()')
    assert body==fn(old,name),name
print('Manticore original bodies preserved:',len(names))
parent = out/'src/monsters/goblin_thrower.gd'
parent.write_text(parent.read_text()+'var combat_authority: Node\nvar hero: Node2D\n')
(out/'tests/goblin_thrower_before.gd').write_text(parent.read_text())
path = out/'src/data/manticore_behavior_catalog.gd'
path.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(a.catalog_baseline,path)
(out/'tests/manticore_audio.gd').write_text('''extends Node
var actor
var callback: Callable
func play_cue(cue):
\tactor.events.append(["cue",cue])
\tif callback.is_valid():callback.call(cue)
func stop_all():
\tactor.events.append("stop_audio")
\tif callback.is_valid():callback.call("stop_all")
func stop_cue(cue):actor.events.append(["stop_cue",cue])
''')
fields = '''const DATA = preload("res://src/data/manticore_behavior_catalog.gd")
enum Motion { REST, FOCUS, HUNT, COMBO, TRACK }
var motion := Motion.REST
var transcend_level := 0
var escaped := false
var guard_remaining := 0.0
var flame_remaining := 0.0
var wave_remaining := 0.0
var meteor_state := PackedInt32Array([1,2,1,2,1,2,1,2,1,2])
var wave_age := PackedFloat32Array([0,1,2,3,4,5,6,7,8,9,10,11])
var audio_bank: Node
var effect_layer: Node2D
var flight_collision_layer := 2
var flight_collision_mask := 3
var destination := Vector2.ZERO
var visual_moving_state := 0
var attack_timer := 0.0
var attack_cooldown := 1.5
'''
for label,source in [('before',old),('after',new)]:
    parent = 'src/monsters/goblin_thrower.gd' if label=='after' else 'tests/goblin_thrower_before.gd'
    methods = ['take_damage','_begin_death','_sfx','_add_shield','_start_track','_begin_flight',
               '_end_motion','effective_range','_clamp_destination']
    if label=='after':
        methods += ['supports_damage_receipt','take_damage_with_result','_apply_manticore_damage',
                    '_begin_death_with_result','_begin_manticore_death']
    path = out/('src/monsters/manticore.gd' if label=='after' else 'tests/manticore_before.gd')
    path.write_text(f'extends "res://{parent}"\n'+fields+''.join(fn(source,n) for n in methods))
(out/'tests/manticore_derived.gd').write_text(
    'extends "res://src/monsters/manticore.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
smoke = (out/'tests/orc_receipt_smoke.gd').read_text().replace(
    'orc_before','manticore_before').replace('src/monsters/orc.gd','src/monsters/manticore.gd').replace(
    'orc_derived','manticore_derived').replace('orc receipt','Manticore receipt')
wave = (out/'tests/orc_wave_receipt_smoke.gd').read_text().replace(
    'src/monsters/orc.gd','src/monsters/manticore.gd')
for label,source in [('manticore_receipt',smoke),('manticore_wave_receipt',wave)]:
    if label=='manticore_wave_receipt':
        source = source.replace('extends SceneTree','extends SceneTree\nconst POPUPS = preload("res://tests/popups.gd")')
    source = source.replace('var hero = Node.new()','var hero = Node2D.new()').replace(
        'class Visual extends Node:','class Visual extends Node2D:').replace(
        '\tfunc play_death():owner_actor.events.append("death")',
        '''\tvar animation: StringName = &"idle"
\tfunc stop():owner_actor.events.append("stop_visual")
\tfunc play(name):owner_actor.events.append(["play",name])
\tfunc play_death():owner_actor.events.append("death")''')
    source = source.replace('\ta.current_hp = hp','\ta.escaped = true\n\ta.current_hp = hp')
    source = source.replace('\ta.visual = visual','''\ta.visual = visual
\tvar audio = load("res://tests/manticore_audio.gd").new()
\taudio.actor = a
\ta.add_child(audio)
\ta.audio_bank = audio
\ta.effect_layer = Node2D.new()
\ta.add_child(a.effect_layer)''')
    who = 'fresh' if label=='manticore_receipt' else 'w.a'
    source = source.replace(who+'.hit_callback = func():',
        'POPUPS.callback = func(_owner,_amount):').replace(
        who+'.hit_callback = Callable()','POPUPS.callback = Callable()')
    source = source.replace(
        '\ta.hit_callback = Callable()','\tPOPUPS.callback = Callable()\n\ta.hit_callback = Callable()').replace(
        '\tw.a.hit_callback = Callable()','\tPOPUPS.callback = Callable()\n\tw.a.hit_callback = Callable()')
    (out/f'tests/{label}_smoke.gd').write_text(source)
    (out/f'tests/{label}_helper.gd').write_text(source.replace(
        'extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
shutil.copy2(ROOT/'tests/manticore_receipt_special_smoke.gd',out/'tests/manticore_receipt_special_smoke.gd')
