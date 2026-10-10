"""Actual ranged actors; inherits existing receipt/wave boundary fixtures."""
from pathlib import Path
import argparse,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path)
for n in ['skeleton-archer','goblin-thrower','kobolt','skeleton','projectile','wave','slime','common']:p.add_argument('--'+n+'-baseline',type=Path,required=True)
a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_skeleton_receipt_fixture.py'),str(out),*[v for n in ['skeleton','projectile','wave','slime','common'] for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]],check=True)
def fn(source,name):
    m=re.search(r'^func '+re.escape(name)+r'\(',source,re.M);assert m,name
    tail=source[m.start():];end=re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
header=(out/'src/monsters/skeleton.gd').read_text().split('func take_damage(')[0]
header+='''var attack_timer := 0.0
var attack_cooldown := 1.5
var attack_windup_timer := -1.0
var burst_shot_timer := -1.0
var burst_shots_remaining := 0
var burst_total_shots := 0
'''
for actor in ['skeleton_archer','goblin_thrower','kobolt']:
    old=getattr(a,actor+'_baseline').read_text();new=(ROOT/f'src/monsters/{actor}.gd').read_text()
    names=re.findall(r'^func ([^(]+)\(',old,re.M)
    for name in names:
        body=fn(new,name)
        if name=='take_damage':
            body=fn(new,'_apply_'+actor+'_damage').replace(f'func _apply_{actor}_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:','func take_damage(amount: int) -> void:').replace('MONSTER_RUNTIME_COMMON._consume_support_shield(self,amount,receipt,receipt_revision)','MONSTER_RUNTIME_COMMON.consume_support_shield(self,amount)').replace('\tif receipt != null:\n\t\treceipt.record_hp(applied_damage, receipt_revision)\n','').replace('\tif receipt != null:\n\t\treceipt.record_hp(previous_hp - current_hp, receipt_revision)\n','').replace('_begin_death(receipt, receipt_revision)','_begin_death()')
        if name=='_begin_death':body=body.replace('(receipt = null, receipt_revision: int = 0)','()').replace('collision_shape,\n\t\t&"_on_death_animation_finished",\n\t\treceipt,\n\t\treceipt_revision','collision_shape')
        assert body==fn(old,name),(actor,name)
    print(actor,'original bodies preserved:',len(names))
    for label,source in [('before',old),('after',new)]:
        methods=['take_damage','_begin_death']
        if actor=='skeleton_archer':methods+=['_can_revive','_begin_revival','_tick_revival','_complete_revival','_cancel_attack_sequence','heal_direct']
        if label=='after':methods+=['supports_damage_receipt','take_damage_with_result','_apply_'+actor+'_damage']
        path=out/(f'src/monsters/{actor}.gd' if label=='after' else f'tests/{actor}_before.gd')
        path.write_text(header.replace('common_after','common_'+label)+''.join(fn(source,n) for n in methods))
    (out/f'tests/{actor}_derived.gd').write_text(f'extends "res://src/monsters/{actor}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    for kind in ['receipt_smoke','wave_receipt_smoke','wave_helper']:
        source=(out/f'tests/skeleton_{kind}.gd').read_text().replace('skeleton_before',actor+'_before').replace('src/monsters/skeleton.gd',f'src/monsters/{actor}.gd').replace('skeleton_derived',actor+'_derived').replace('Skeleton receipt',actor+' receipt')
        (out/f'tests/{actor}_{kind}.gd').write_text(source)
(out/'tests/ranged_revival_smoke.gd').write_text((ROOT/'tests/ranged_revival_smoke.gd').read_text())
