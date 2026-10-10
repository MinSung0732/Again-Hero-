"""Compare every Hero function before hooks; execute actual status and AI event slices."""
from pathlib import Path
import argparse
import re
import shutil
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('target',type=Path)
for n in ['hero','action-scope','event-buffer','monster-catalog']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
old=a.hero_baseline.read_text();new=(ROOT/'src/hero/hero.gd').read_text()
def fn(s,n):
    m=re.search(r'^func '+re.escape(n)+r'\(',s,re.M);assert m,n
    tail=s[m.start():];end=re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
names=re.findall(r'^func ([^(]+)\(',old,re.M)
for n in names:
    body=fn(new,n)
    if n in ['apply_slow','apply_stun','apply_silence','apply_fear','apply_paralysis','apply_petrify']:
        kind=n.split('_')[1]
        body=fn(new,'_apply_'+kind+'_status').replace('_apply_'+kind+'_status',n,1).replace(', receipt = null, receipt_revision: int = 0','')
        body=body.replace('speed_multiplier: float = 1.50,\n\treceipt = null,\n\treceipt_revision: int = 0','speed_multiplier: float = 1.50')
        body=re.sub(r'\tif receipt != null:\n\t\treceipt.record_application\([^\n]+\)\n','',body)
    assert body==fn(old,n),n
print('Hero original bodies preserved:',len(names))
cat=a.monster_catalog_baseline.read_text();ids=re.findall(r'"([a-z_]+)"',cat.split('const ORDER := [',1)[1].split(']',1)[0])
for actor in ids:
    s=(ROOT/f'src/monsters/{actor}.gd').read_text()
    assert 'func supports_damage_receipt()' in s,actor
    assert 'res://src/monsters/'+actor+'.gd' in fn(s,'supports_damage_receipt'),actor
print('Catalog actor incoming opt-in audit:',len(ids))
for d in ['src/hero','src/systems','tests']:(out/d).mkdir(parents=True,exist_ok=True)
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Hero status receipt fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
shutil.copy2(a.action_scope_baseline,out/'src/systems/status_action_scope.gd')
shutil.copy2(a.event_buffer_baseline,out/'src/systems/timed_event_buffer.gd')
for n in ['battle_status_receipt','battle_entity_registry']:shutil.copy2(ROOT/f'src/systems/{n}.gd',out/f'src/systems/{n}.gd')
header='''extends CharacterBody2D
const STATUS_ACTION_SCOPE = preload("res://src/systems/status_action_scope.gd")
const TIMED_EVENT_BUFFER = preload("res://src/systems/timed_event_buffer.gd")
signal status_applied(status_id: String)
signal status_action_applied(status_id: String)
const STATUS_MEMORY_WINDOW := 20.0
var current_hp := 100
var is_dying := false
var resistance := 0.0
var ai_memory_clock := 0.0
var status_effect_events = TIMED_EVENT_BUFFER.new()
var silence_timer := 0.0
var stun_timer := 0.0
var slow_timer := 0.0
var move_multiplier := 1.0
var hero_sprite: Node
var stun_sprite_speed := 1.0
func get_status_resistance(_kind) -> float:return resistance
'''
methods=['apply_slow','apply_stun','apply_silence','record_status_effect_event','_prune_status_memory']
for label,s in [('before',old),('after',new)]:
    extra=[] if label=='before' else ['supports_status_receipt','apply_slow_with_result','apply_stun_with_result','apply_silence_with_result','_apply_slow_status','_apply_stun_status','_apply_silence_status']
    path=out/('src/hero/hero.gd' if label=='after' else 'tests/hero_status_before.gd')
    path.write_text(header+''.join(fn(s,n) for n in methods+extra))
(out/'tests/hero_status_derived.gd').write_text('''extends "res://src/hero/hero.gd"
var legacy_calls := 0
func apply_slow(_multiplier,_duration):legacy_calls += 1
func apply_stun(_duration):legacy_calls += 1
func apply_silence(_duration):
\tlegacy_calls += 1
\treturn true
''')
shutil.copy2(ROOT/'tests/hero_status_receipt_smoke.gd',out/'tests/hero_status_receipt_smoke.gd')
