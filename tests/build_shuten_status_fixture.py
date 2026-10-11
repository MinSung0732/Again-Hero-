"""Actual ReceivedAfflictions and Shuten status callers with Hero/generic regressions."""
from pathlib import Path
import argparse, re, shutil, subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(); p.add_argument('target', type=Path)
base = ['hero','control-hero','extended-hero','dot-hero','action-scope','event-buffer','monster-catalog','medusa','burn','damage-poison','succubus','izanami']
for n in base + ['afflictions','shuten','shuten-catalog']:
    p.add_argument('--' + n + '-baseline', type=Path, required=True)
a = p.parse_args(); out = a.target.resolve()
if out == ROOT or ROOT in out.parents: raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable, str(ROOT / 'tests/build_izanami_status_fixture.py'), str(out),
    *[v for n in base for v in ['--' + n + '-baseline', str(getattr(a, n.replace('-', '_') + '_baseline'))]]], check=True)
def fn(s, n):
    m = re.search(r'^(?:static )?func ' + re.escape(n) + r'\(', s, re.M); assert m, n
    tail = s[m.start():]; end = re.search(r'\n(?:static )?func ', tail)
    return (tail[:end.start()] if end else tail).rstrip() + '\n\n'
old = a.afflictions_baseline.read_text(); new = (ROOT / 'src/systems/received_afflictions.gd').read_text()
assert new.startswith(old.rstrip()), 'Existing component fields and methods changed'
names = re.findall(r'^(?:static )?func ([^(]+)\(', old, re.M)
for n in names: assert fn(old, n) == fn(new, n), n
print('ReceivedAfflictions original bodies preserved:', len(names))
shutil.copy2(a.afflictions_baseline, out / 'tests/afflictions_before.gd')
shutil.copy2(ROOT / 'src/systems/received_afflictions.gd', out / 'src/systems/received_afflictions.gd')
(out / 'src/ui').mkdir(exist_ok=True)
shutil.copy2(out / 'tests/status_visual_spy.gd', out / 'src/ui/combat_status_effect_visual.gd')
shutil.copy2(a.shuten_catalog_baseline, out / 'src/data/shuten_doji_behavior_catalog.gd')
old = a.shuten_baseline.read_text(); new = (ROOT / 'src/monsters/shuten_doji.gd').read_text()
names = re.findall(r'^func ([^(]+)\(', old, re.M)
for n in names:
    body = fn(new, n).replace('\tstatus_result_complete = false\n', '')
    body = body.replace('status_result_complete = AFFLICTIONS.', 'AFFLICTIONS.').replace('_with_result(target,', '(target,').replace(',status_receipt,_action_token', ',_action_token')
    assert body == fn(old, n), n
print('Shuten original bodies preserved:', len(names))
fields = '''extends Node2D
const DATA = preload("res://src/data/shuten_doji_behavior_catalog.gd")
const STATUS_SCOPE = preload("res://src/systems/status_action_scope.gd")
var hero: Node2D
var attack_damage := 220
var clock := 0.0
var transcend_level := 0
var action_serial := 0
var status_actions: Dictionary = {}
var records: Dictionary = {}
var fog_points := PackedVector2Array([Vector2.ZERO])
var fog_damage := PackedFloat32Array([30])
var fog_life := PackedFloat32Array([5])
var fog_power := PackedFloat32Array([1])
var fog_action := PackedInt32Array([1])
var chain_age := PackedFloat32Array([0])
var chain_state := PackedByteArray([1])
var chain_action := PackedInt32Array([1])
var chain_immunity: Dictionary = {}
var cooldowns := PackedFloat32Array([20,0,60])
var damage_events: Array = []
var audio_events: Array = []
func _audio(kind):audio_events.append(kind)
func _damage(target,amount,followup=true,dot=false):
\tdamage_events.append([amount,followup,dot])
\ttarget.current_hp = maxi(target.current_hp-amount,0)
\treturn amount>0
'''
methods = ['_apply_fog','_blast_target','_apply_stun','_bind_chain','_next_action','_action_token','_record']
for label, s in [('before', old), ('after', new)]:
    extra = '''const STATUS_RECEIPT = preload("res://src/systems/battle_status_receipt.gd")
var status_receipt = STATUS_RECEIPT.new()
var status_result_complete := false
''' if label == 'after' else ''
    affliction_path = 'src/systems/received_afflictions.gd' if label == 'after' else 'tests/afflictions_before.gd'
    (out / ('tests/shuten_status_' + label + '.gd')).write_text(fields + extra + 'const AFFLICTIONS = preload("res://' + affliction_path + '")\n' + ''.join(fn(s, n) for n in methods))
shutil.copy2(ROOT / 'tests/shuten_status_receipt_smoke.gd', out / 'tests/shuten_status_receipt_smoke.gd')
