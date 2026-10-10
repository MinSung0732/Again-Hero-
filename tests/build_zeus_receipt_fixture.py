"""Validate Zeus incoming hooks using actual Thrower and existing receipt fixtures."""
from pathlib import Path
import argparse
import re
import subprocess
import sys
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
base = ['izanami','shuten','izanami-catalog','shuten-catalog','wolf','scorpion','orc','spider','projectile','wave','slime','common']
for n in base+['zeus']:
    p.add_argument('--'+n+'-baseline',type=Path,required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable,str(ROOT/'tests/build_control_transcendent_receipt_fixture.py'),str(out),
    *[v for n in base for v in ['--'+n+'-baseline',str(getattr(a,n.replace('-','_')+'_baseline'))]]],check=True)
def fn(s,n):
    m=re.search(r'^func '+re.escape(n)+r'\(',s,re.M);assert m,n
    tail=s[m.start():];end=re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
old=a.zeus_baseline.read_text();new=(ROOT/'src/monsters/zeus.gd').read_text()
names=re.findall(r'^func ([^(]+)\(',old,re.M)
for n in names:
    body=fn(new,n)
    if n=='take_damage':
        body=fn(new,'_apply_zeus_damage').replace(
            'func _apply_zeus_damage(amount: int, receipt = null, receipt_revision: int = 0)',
            'func take_damage(amount: int)').replace(
            'super._apply_goblin_thrower_damage(amount, receipt, receipt_revision)','super.take_damage(amount)')
    if n=='_begin_death':
        body=fn(new,'_begin_zeus_death').replace(
            'func _begin_zeus_death(receipt = null, receipt_revision: int = 0)','func _begin_death()').replace(
            'super._begin_death_with_result(receipt, receipt_revision)','super._begin_death()')
    assert body==fn(old,n),('zeus',n)
print('Zeus original bodies preserved:',len(names))
for label,s in [('before',old),('after',new)]:
    parent='src/monsters/goblin_thrower.gd' if label=='after' else 'tests/goblin_thrower_before.gd'
    methods=['take_damage','_begin_death','play_combat_sound']
    if label=='after':methods+=['supports_damage_receipt','take_damage_with_result','_apply_zeus_damage','_begin_death_with_result','_begin_zeus_death']
    path=out/('src/monsters/zeus.gd' if label=='after' else 'tests/zeus_before.gd')
    path.write_text(f'extends "res://{parent}"\nvar combat_sfx: Node\nvar effect_layer: Node2D\n'+''.join(fn(s,n) for n in methods))
(out/'tests/zeus_derived.gd').write_text('extends "res://src/monsters/zeus.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
for label in ['receipt','wave_receipt']:
    s=(out/f'tests/izanami_{label}_smoke.gd').read_text().replace('izanami','zeus')
    start=s.index('\ta.hero = scope.hero\n');end=s.index('\ta.current_hp = hp',start)
    s=s[:start]+'''\ta.hero = scope.hero
\ta.effect_layer = Node2D.new()
\ta.add_child(a.effect_layer)
\ta.combat_sfx = load("res://tests/control_audio.gd").new()
\ta.combat_sfx.actor = a
\ta.add_child(a.combat_sfx)
'''+s[end:]
    (out/f'tests/zeus_{label}_smoke.gd').write_text(s)
    (out/f'tests/zeus_{label}_helper.gd').write_text(s.replace('extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
import shutil
shutil.copy2(ROOT/'tests/zeus_receipt_audio_smoke.gd',out/'tests/zeus_receipt_audio_smoke.gd')
