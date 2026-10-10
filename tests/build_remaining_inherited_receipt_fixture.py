"""Actual parent/child incoming damage and actor death hooks; visuals are spies."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target',type=Path)
for n in ['medusa','yuki-onna','powwow-mummy','kraken','catalog','wolf','scorpion','orc','spider','projectile','wave','slime','common']:
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
for path in ['src/monsters/orc.gd','tests/orc_before.gd']:
    p = out/path;p.write_text(p.read_text()+'var hero: Node2D\n')
p = out/'src/monsters/goblin_thrower.gd';p.write_text(p.read_text()+'var combat_authority: Node\nvar hero: Node2D\n')
(out/'tests/goblin_thrower_before.gd').write_text(p.read_text())
p = out/'src/data/kraken_behavior_catalog.gd';p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a.catalog_baseline,p)
(out/'tests/tentacle_spy.gd').write_text('''extends RefCounted
static var calls: Array = []
static func show_at(authority,spot,visual_scale):
\tcalls.append([spot,visual_scale])
\tif is_instance_valid(authority):authority.note_tentacle(spot)
''')
for actor in ['medusa','yuki_onna','powwow_mummy','kraken']:
    old = getattr(a,actor+'_baseline').read_text();new = (ROOT/f'src/monsters/{actor}.gd').read_text()
    names = re.findall(r'^func ([^(]+)\(',old,re.M)
    for name in names:
        body = fn(new,name)
        if name=='_begin_death':body = fn(new,'_begin_'+actor+'_death').replace(
            'func _begin_'+actor+'_death(receipt = null, receipt_revision: int = 0)', 'func _begin_death()').replace(
            'super._begin_death_with_result(receipt, receipt_revision)','super._begin_death()')
        assert body==fn(old,name),(actor,name)
    print(actor,'original bodies preserved:',len(names))
    parent = 'orc' if actor in ['medusa','kraken'] else 'goblin_thrower'
    for label,source in [('before',old),('after',new)]:
        parent_path = f'src/monsters/{parent}.gd' if label=='after' else f'tests/{parent}_before.gd'
        content = f'extends "res://{parent_path}"\n'
        methods = [] if actor=='powwow_mummy' else ['_begin_death']
        if actor=='kraken':
            content += '''const BEHAVIOR = preload("res://src/data/kraken_behavior_catalog.gd")
const TENTACLE = preload("res://tests/tentacle_spy.gd")
var burst_count := 0
var attack_damage := 66
var growth_hits := 0
var growth_stacks := 0
'''
            methods += ['_strike']
        if label=='after':
            methods += ['supports_damage_receipt']
            if actor!='powwow_mummy':methods += ['_begin_death_with_result','_begin_'+actor+'_death']
        path = out/(f'src/monsters/{actor}.gd' if label=='after' else f'tests/{actor}_before.gd')
        path.write_text(content+''.join(fn(source,n) for n in methods))
    (out/f'tests/{actor}_derived.gd').write_text(f'extends "res://src/monsters/{actor}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    # Existing complete boundary matrix applies to both incoming parent bodies.
    smoke = (out/'tests/orc_receipt_smoke.gd').read_text().replace('orc_before',actor+'_before').replace(
        'src/monsters/orc.gd',f'src/monsters/{actor}.gd').replace('orc_derived',actor+'_derived').replace(
        'orc receipt',actor+' receipt')
    wave = (out/'tests/orc_wave_receipt_smoke.gd').read_text().replace('src/monsters/orc.gd',f'src/monsters/{actor}.gd')
    if parent=='goblin_thrower':
        smoke = smoke.replace('fresh.hit_callback = func():fresh.dying = true',
            'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\tfresh.dying = true')
        wave = wave.replace('extends SceneTree','extends SceneTree\nconst POPUPS = preload("res://tests/popups.gd")').replace(
            'w.a.hit_callback = func():w.a.dying = true',
            'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()\n\t\tw.a.dying = true').replace(
            'w.a.hit_callback = func():\n\t\tw.a.hit_callback = Callable()',
            'POPUPS.callback = func(_owner,_amount):\n\t\tPOPUPS.callback = Callable()')
    (out/f'tests/{actor}_receipt_smoke.gd').write_text(smoke)
    (out/f'tests/{actor}_wave_receipt_smoke.gd').write_text(wave)
shutil.copy2(ROOT/'tests/remaining_inherited_receipt_smoke.gd',out/'tests/remaining_inherited_receipt_smoke.gd')
