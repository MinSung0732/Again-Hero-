"""Extend original status fixture with actual fear/paralysis/petrify and release."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path)
base=['hero','action-scope','event-buffer','monster-catalog']
for n in base+['control-hero','medusa']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_hero_status_receipt_fixture.py'),str(out),
    *[v for n in base for v in ['--'+n+'-baseline',str(getattr(a,n.replace('-','_')+'_baseline'))]]],check=True)
def fn(s,n):
    m=re.search(r'^func '+re.escape(n)+r'\(',s,re.M);assert m,n
    tail=s[m.start():];end=re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
old=a.control_hero_baseline.read_text();new=(ROOT/'src/hero/hero.gd').read_text()
names=re.findall(r'^func ([^(]+)\(',old,re.M)
for n in names:
    body=fn(new,n)
    if n in ['apply_fear','apply_paralysis','apply_petrify']:
        kind=n.split('_')[1]
        body=fn(new,'_apply_'+kind+'_status').replace('_apply_'+kind+'_status',n,1).replace(', receipt = null, receipt_revision: int = 0','')
        body=body.replace('speed_multiplier: float = 1.50,\n\treceipt = null,\n\treceipt_revision: int = 0','speed_multiplier: float = 1.50')
        body=re.sub(r'\tif receipt != null:\n\t\treceipt.record_application\([^\n]+\)\n','',body)
    assert body==fn(old,n),n
print('Current Hero bodies preserved:',len(names))
(out/'src/data').mkdir(exist_ok=True)
shutil.copy2(a.medusa_baseline,out/'src/data/medusa_behavior_catalog.gd')
(out/'tests/status_visual_spy.gd').write_text('''extends RefCounted
static func show_on(actor,kind):
\tactor.fx_events.append(kind)
\tif actor.fx_callback.is_valid():actor.fx_callback.call(kind)
''')
fields='''const MEDUSA_BEHAVIOR = preload("res://src/data/medusa_behavior_catalog.gd")
const COMBAT_STATUS_EFFECT_VISUAL = preload("res://tests/status_visual_spy.gd")
var fx_events: Array = []
var fx_callback: Callable
var fear_timer := 0.0
var fear_source: Node2D
var fear_origin := Vector2.ZERO
var fear_speed_multiplier := 1.0
var possession_immunity_timer := 0.0
var paralysis_ratio := 0.0
var paralysis_timer := 0.0
var attack_timer := 0.0
var rogue_slash_cooldown_timer := 0.0
var petrify_timer := 0.0
var petrify_anchor := Vector2.ZERO
var petrify_status_action: RefCounted
var petrify_release_slow := 1.0
var petrify_release_slow_duration := 0.0
var petrify_restore_tint := Color.WHITE
'''
methods=['apply_fear','apply_paralysis','apply_petrify','_tick_petrify','get_paralysis_attack_multiplier']
for label,s in [('before',old),('after',new)]:
    path=out/('src/hero/hero.gd' if label=='after' else 'tests/hero_status_before.gd')
    if label=='before':
        # Preserve current-stage helpers in baseline so delayed residue uses the same legacy API.
        old_header=path.read_text().split('func apply_slow(')[0]
        original_methods=['apply_slow','apply_stun','apply_silence','record_status_effect_event','_prune_status_memory',
            'supports_status_receipt','apply_slow_with_result','apply_stun_with_result','apply_silence_with_result',
            '_apply_slow_status','_apply_stun_status','_apply_silence_status']
        path.write_text(old_header+''.join(fn(old,n) for n in original_methods))
    extra=[] if label=='before' else [x for kind in ['fear','paralysis','petrify'] for x in ['apply_'+kind+'_with_result','_apply_'+kind+'_status']]
    path.write_text(path.read_text()+fields+''.join(fn(s,n) for n in methods+extra))
with (out/'tests/hero_status_derived.gd').open('a') as f:
    f.write('''func apply_fear(_source,_duration,_speed_multiplier=1.5):legacy_calls += 1
func apply_paralysis(_ratio,_duration):
\tlegacy_calls += 1
\treturn true
func apply_petrify(_duration,_release_slow=1.0,_release_duration=0.0):
\tlegacy_calls += 1
\treturn true
''')
shutil.copy2(ROOT/'tests/hero_extended_status_smoke.gd',out/'tests/hero_extended_status_smoke.gd')

helper=(out/'tests/hero_status_receipt_smoke.gd').read_text().replace('extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass')
(out/'tests/hero_status_receipt_helper.gd').write_text(helper)
