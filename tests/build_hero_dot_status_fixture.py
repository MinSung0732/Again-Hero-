"""Actual DOT application/tick slices with legacy state and budget comparison."""
from pathlib import Path
import argparse,re,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path)
base=['hero','control-hero','action-scope','event-buffer','monster-catalog','medusa']
for n in base+['extended-hero','burn','damage-poison']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_hero_extended_status_fixture.py'),str(out),
    *[v for n in base for v in ['--'+n+'-baseline',str(getattr(a,n.replace('-','_')+'_baseline'))]]],check=True)
def fn(s,n):
    m=re.search(r'^func '+re.escape(n)+r'\(',s,re.M);assert m,n
    tail=s[m.start():];end=re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
old=a.extended_hero_baseline.read_text();new=(ROOT/'src/hero/hero.gd').read_text()
names=re.findall(r'^func ([^(]+)\(',old,re.M)
for n in names:
    body=fn(new,n)
    if n in ['apply_poison','apply_damage_poison','apply_bleed','apply_burn']:
        kind=n[6:]
        body=fn(new,'_apply_'+kind+'_status').replace('_apply_'+kind+'_status',n,1).replace(', receipt = null, receipt_revision: int = 0','')
        body=body.replace('source: Node = null,\n\treceipt = null,\n\treceipt_revision: int = 0','source: Node = null')
        body=re.sub(r'\tif receipt != null:\n(?:\t\treceipt\.(?:record_application|record_damage_budget)\([^\n]+\)\n)+','',body)
    assert body==fn(old,n),n
print('Extended Hero bodies preserved:',len(names))
shutil.copy2(a.burn_baseline,out/'src/systems/burn_runtime.gd')
shutil.copy2(a.damage_poison_baseline,out/'src/systems/damage_poison_tracker.gd')
fields='''const BURN_RUNTIME = preload("res://src/systems/burn_runtime.gd")
const DAMAGE_POISON_TRACKER = preload("res://src/systems/damage_poison_tracker.gd")
var burn_runtime = BURN_RUNTIME.new()
var damage_poison_tracker = DAMAGE_POISON_TRACKER.new()
var max_hp := 1000
var poison_timer := 0.0
var poison_tick_interval := 0.5
var poison_ticks_remaining := 0
var poison_damage_remaining := 0
var poison_tick_timer := 0.0
var poison_source: Node
var poison_flash_timer := 0.0
var poison_flash_active := false
var poison_flash_restore_color := Color.WHITE
var bleed_timer := 0.0
var bleed_duration := 0.0
var bleed_elapsed := 0.0
var bleed_tick_timer := 0.0
var bleed_total_damage := 0
var bleed_damage_applied := 0
var bleed_source: Node
var damage_events: Array = []
var damage_callback: Callable
func take_status_damage(amount,source) -> bool:
\tdamage_events.append([amount,source.get_instance_id() if is_instance_valid(source) else 0])
\tcurrent_hp = maxi(current_hp-amount,0)
\tif damage_callback.is_valid():damage_callback.call()
\treturn amount>0
func _take_damage_internal(amount,source,_a,_b,_c) -> bool:return take_status_damage(amount,source)
'''
methods=['apply_poison','apply_damage_poison','apply_bleed','apply_burn','_update_poison','_set_poison_flash',
    '_update_bleed','_clear_bleed','_clear_burn','_update_damage_poison','take_recorded_poison_damage']
for label,s in [('before',old),('after',new)]:
    path=out/('src/hero/hero.gd' if label=='after' else 'tests/hero_status_before.gd')
    extra=[] if label=='before' else [x for kind in ['poison','damage_poison','bleed','burn'] for x in ['apply_'+kind+'_with_result','_apply_'+kind+'_status']]
    path.write_text(path.read_text()+fields+''.join(fn(s,n) for n in methods+extra))
with (out/'tests/hero_status_derived.gd').open('a') as f:
    f.write('''func apply_poison(_duration,_ratio,_interval=0.5,_source=null):legacy_calls += 1
func apply_damage_poison(_duration,_total,_source,_channel=0):
\tlegacy_calls += 1
\treturn true
func apply_bleed(_duration=5.0,_source=null,_ratio=-1.0,_refresh=false):
\tlegacy_calls += 1
\treturn true
func apply_burn(_duration,_total,_source=null):
\tlegacy_calls += 1
\treturn true
''')
shutil.copy2(ROOT/'tests/hero_dot_status_smoke.gd',out/'tests/hero_dot_status_smoke.gd')
