"""Real Orc/Bulgasal incoming damage, channel cancel and pillar retirement hooks."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target',type=Path)
for n in ['bulgasal','catalog','channel','policy','pillars','wolf','scorpion','orc','spider','projectile','wave','slime','common']:
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

old = a.bulgasal_baseline.read_text()
new = (ROOT/'src/monsters/bulgasal.gd').read_text()
names = re.findall(r'^func ([^(]+)\(',old,re.M)
for name in names:
    body = fn(new,name)
    if name=='take_damage':
        body = fn(new,'_apply_bulgasal_damage').replace(
            'func _apply_bulgasal_damage(amount: int, receipt = null, receipt_revision: int = 0)',
            'func take_damage(amount: int)').replace(
            '\t# Count the incoming hit before shield absorption, as in the legacy path.\n','').replace(
            'super._apply_orc_damage(int(round(amount*DATA.BURROW_DAMAGE_RATIO)) if phase == "burrow" else amount, receipt, receipt_revision)',
            'super.take_damage(int(round(amount*DATA.BURROW_DAMAGE_RATIO)) if phase == "burrow" else amount)')
    if name=='_begin_death':
        body = fn(new,'_begin_bulgasal_death').replace(
            'func _begin_bulgasal_death(receipt = null, receipt_revision: int = 0)',
            'func _begin_death()').replace(
            'super._begin_death_with_result(receipt, receipt_revision)','super._begin_death()')
    assert body==fn(old,name),name
print('Bulgasal original bodies preserved:',len(names))
for source,target in [(a.catalog_baseline,'src/data/bulgasal_behavior_catalog.gd'),
                      (a.channel_baseline,'src/systems/channel_runtime.gd'),
                      (a.policy_baseline,'src/systems/hero_target_policy.gd')]:
    path = out/target
    path.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,path)
(out/'tests/bulgasal_pillars.gd').write_text('''extends Node2D
var actor
var retiring := false
var shatter_calls: Array = []
var callback: Callable
func shatter_all(damage):
\tshatter_calls.append(damage)
\tactor.events.append("pillars")
\tif callback.is_valid():callback.call()
'''+fn(a.pillars_baseline.read_text(),'finish_death'))
(out/'tests/bulgasal_audio.gd').write_text('''extends Node
var actor
var callback: Callable
func stop_all():
\tactor.events.append("stop_audio")
\tif callback.is_valid():callback.call()
''')
fields = '''const DATA = preload("res://src/data/bulgasal_behavior_catalog.gd")
const TARGET_POLICY = preload("res://src/systems/hero_target_policy.gd")
const CHANNEL = preload("res://src/systems/channel_runtime.gd")
var channel = CHANNEL.new()
var phase := "idle"
var transcend_level := 0
var received_hits := 0
var retreat_pending := 0
var burrow_phased := false
var burrow_saved_layer := 0
var burrow_saved_mask := 0
var fragment_states := PackedInt32Array([1,2,1,2,1,2,1,2])
var fragment_hit := true
var rock_active := true
var wave_active := true
var wave_visual_distance := 14.0
var visual_rest := Vector2(11,-9)
var audio_bank: Node
var pillars: Node2D
var effect_layer: Node2D
var gauge_layer: Node2D
'''
for label,source in [('before',old),('after',new)]:
    parent = 'src/monsters/orc.gd' if label=='after' else 'tests/orc_before.gd'
    methods = ['take_damage','_begin_death','_restore_burrow_collision']
    if label=='after':
        methods += ['supports_damage_receipt','take_damage_with_result','_apply_bulgasal_damage',
                    '_begin_death_with_result','_begin_bulgasal_death']
    path = out/('src/monsters/bulgasal.gd' if label=='after' else 'tests/bulgasal_before.gd')
    path.write_text(f'extends "res://{parent}"\n'+fields+''.join(fn(source,n) for n in methods))
(out/'tests/bulgasal_derived.gd').write_text(
    'extends "res://src/monsters/bulgasal.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
smoke = (out/'tests/orc_receipt_smoke.gd').read_text().replace(
    'orc_before','bulgasal_before').replace('src/monsters/orc.gd','src/monsters/bulgasal.gd').replace(
    'orc_derived','bulgasal_derived').replace('orc receipt','Bulgasal receipt')
wave = (out/'tests/orc_wave_receipt_smoke.gd').read_text().replace(
    'src/monsters/orc.gd','src/monsters/bulgasal.gd')
for label,source in [('bulgasal_receipt',smoke),('bulgasal_wave_receipt',wave)]:
    source = source.replace('class Visual extends Node:','class Visual extends Node2D:')
    source = source.replace('\ta.visual = visual','''\ta.visual = visual
\tvar pillars = load("res://tests/bulgasal_pillars.gd").new()
\tpillars.actor = a
\ta.add_child(pillars)
\ta.pillars = pillars
\tvar audio = load("res://tests/bulgasal_audio.gd").new()
\taudio.actor = a
\ta.add_child(audio)
\ta.audio_bank = audio
\ta.effect_layer = Node2D.new()
\ta.gauge_layer = Node2D.new()
\ta.add_child(a.effect_layer)
\ta.add_child(a.gauge_layer)''')
    (out/f'tests/{label}_smoke.gd').write_text(source)
    (out/f'tests/{label}_helper.gd').write_text(source.replace(
        'extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
shutil.copy2(ROOT/'tests/bulgasal_receipt_special_smoke.gd',out/'tests/bulgasal_receipt_special_smoke.gd')
