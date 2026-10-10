"""Real Thrower/Izanami/Shuten incoming damage and death/revival slices."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target',type=Path)
for n in ['izanami','shuten','izanami-catalog','shuten-catalog','wolf','scorpion','orc','spider','projectile','wave','slime','common']:
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
parent = out/'src/monsters/goblin_thrower.gd'
parent.write_text(parent.read_text()+'var combat_authority: Node\nvar hero: Node2D\n')
(out/'tests/goblin_thrower_before.gd').write_text(parent.read_text())
for n in ['izanami','shuten']:
    actor = 'izanami' if n=='izanami' else 'shuten_doji'
    old = getattr(a,n+'_baseline').read_text();new = (ROOT/f'src/monsters/{actor}.gd').read_text()
    names = re.findall(r'^func ([^(]+)\(',old,re.M)
    for name in names:
        body = fn(new,name)
        if name=='take_damage':
            body = fn(new,'_apply_shuten_damage').replace(
                'func _apply_shuten_damage(amount: int, receipt = null, receipt_revision: int = 0)',
                'func take_damage(amount: int)').replace(
                'MONSTER_RUNTIME_COMMON._consume_support_shield(self,reduced,receipt,receipt_revision)',
                'MONSTER_RUNTIME_COMMON.consume_support_shield(self,reduced)').replace(
                '\tvar previous_hp := current_hp\n','').replace(
                '\t\tif receipt != null:\n\t\t\treceipt.record_hp(maxi(previous_hp-current_hp,0), receipt_revision)\n','').replace(
                '\tif receipt != null:\n\t\treceipt.record_hp(maxi(previous_hp-current_hp,0), receipt_revision)\n','').replace(
                '\tif current_hp <= 0:\n\t\tif receipt == null:\n\t\t\t_begin_death()\n\t\telse:\n\t\t\t_begin_death_with_result(receipt, receipt_revision)',
                '\tif current_hp <= 0: _begin_death()')
        if name=='_begin_death':
            body = fn(new,'_begin_'+n+'_death').replace(
                'func _begin_'+n+'_death(receipt = null, receipt_revision: int = 0)',
                'func _begin_death()').replace(
                'super._begin_death_with_result(receipt, receipt_revision)','super._begin_death()')
        assert body==fn(old,name),(actor,name)
    print(actor,'original bodies preserved:',len(names))
    catalog = out/f'src/data/{actor}_behavior_catalog.gd';catalog.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(getattr(a,n+'_catalog_baseline'),catalog)
    fields = f'const DATA = preload("res://src/data/{actor}_behavior_catalog.gd")\n'
    if n=='izanami':
        fields += '''var ghost_remaining := 5.0
var fan_remaining := 2.0
var fire_age := PackedFloat32Array([0,1,2,3])
var spirit_state := PackedInt32Array([1,2,3,4,1,2,3,4])
var torii_age := PackedFloat32Array([0,1,2,3])
var crossing_records: Dictionary = {1:"cached"}
var effect_layer: Node2D
var torii_layer: Node2D
var incoming_signal_hits := 0
func _on_accepted_hit(_source):incoming_signal_hits += 1
'''
    else:
        fields += '''var audio_bank: Node
var transcend_level := 0
var released := false
var revival_used := false
var revival_remaining := 0.0
var revival_heal_fraction := 0.0
var basic_hits := 5
var attack_remaining := 0.6
var self_fog_power := 0.0
var fog_age := PackedFloat32Array()
var blast_age := PackedFloat32Array()
var chain_state := PackedByteArray([1,2,1,2])
var effect_layer: Node2D
var status_layer: Node2D
'''
    for label,source in [('before',old),('after',new)]:
        parent = 'src/monsters/goblin_thrower.gd' if label=='after' else 'tests/goblin_thrower_before.gd'
        methods = ['_begin_death']
        if n=='shuten':methods += ['take_damage','_start_revival','_tick_revival','_add_shield','_audio']
        if label=='after':
            methods += ['supports_damage_receipt','_begin_death_with_result','_begin_'+n+'_death']
            if n=='shuten':methods += ['take_damage_with_result','_apply_shuten_damage']
        path = out/(f'src/monsters/{actor}.gd' if label=='after' else f'tests/{actor}_before.gd')
        path.write_text(f'extends "res://{parent}"\n'+fields+''.join(fn(source,x) for x in methods))
    (out/f'tests/{actor}_derived.gd').write_text(
        f'extends "res://src/monsters/{actor}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    for label,base in [('receipt','orc_receipt'),('wave_receipt','orc_wave_receipt')]:
        s = (out/f'tests/{base}_smoke.gd').read_text().replace('orc_before',actor+'_before').replace(
            'src/monsters/orc.gd',f'src/monsters/{actor}.gd').replace('orc_derived',actor+'_derived').replace(
            'orc receipt',actor+' receipt')
        if label=='receipt':
            s = s.replace('class Scope extends Node:','class Hero extends Node2D:\n\tsignal accepted_damage_hit(source)\nclass Scope extends Node:').replace(
                'var hero = Node.new()','var hero = Hero.new()')
        else:
            s = s.replace('extends SceneTree','extends SceneTree\nconst POPUPS = preload("res://tests/popups.gd")').replace(
                'class Hero extends Node2D:','class Hero extends Node2D:\n\tsignal accepted_damage_hit(source)')
        s = s.replace('class Visual extends Node:','class Visual extends Node2D:').replace(
            '\tfunc play_death():owner_actor.events.append("death")','''\tvar animation: StringName = &"idle"
\tvar frame := 0
\tfunc stop():owner_actor.events.append("stop_visual")
\tfunc play(name):owner_actor.events.append(["play",name])
\tfunc play_death():owner_actor.events.append("death")''')
        setup = '\ta.hero = scope.hero\n'
        if n=='izanami':
            setup += '''\ta.hero.accepted_damage_hit.connect(a._on_accepted_hit)
\ta.effect_layer = Node2D.new()
\ta.torii_layer = Node2D.new()
\ta.add_child(a.effect_layer)
\ta.add_child(a.torii_layer)
'''
        else:
            setup += '''\ta.revival_used = true
\ta.fog_age.resize(a.DATA.FOG_CAPACITY)
\ta.fog_age.fill(1.0)
\ta.blast_age.resize(a.DATA.FOG_CAPACITY)
\ta.blast_age.fill(1.0)
\ta.effect_layer = Node2D.new()
\ta.status_layer = Node2D.new()
\ta.add_child(a.effect_layer)
\ta.add_child(a.status_layer)
\tvar audio = load("res://tests/control_audio.gd").new()
\taudio.actor = a
\ta.add_child(audio)
\ta.audio_bank = audio
'''
        s = s.replace('\ta.current_hp = hp',setup+'\ta.current_hp = hp')
        who = 'fresh' if label=='receipt' else 'w.a'
        s = s.replace(who+'.hit_callback = func():','POPUPS.callback = func(_owner,_amount):').replace(
            who+'.hit_callback = Callable()','POPUPS.callback = Callable()')
        s = s.replace('\ta.hit_callback = Callable()','\tPOPUPS.callback = Callable()\n\ta.hit_callback = Callable()').replace(
            '\tw.a.hit_callback = Callable()','\tPOPUPS.callback = Callable()\n\tw.a.hit_callback = Callable()')
        (out/f'tests/{actor}_{label}_smoke.gd').write_text(s)
        (out/f'tests/{actor}_{label}_helper.gd').write_text(s.replace(
            'extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
(out/'tests/control_audio.gd').write_text('''extends Node
var actor
var callback: Callable
func play_cue(cue):
\tactor.events.append(["cue",cue])
\tif callback.is_valid():callback.call(cue)
func stop_all():
\tactor.events.append("stop_audio")
\tif callback.is_valid():callback.call("stop_all")
''')
shutil.copy2(ROOT/'tests/control_transcendent_receipt_smoke.gd',out/'tests/control_transcendent_receipt_smoke.gd')
