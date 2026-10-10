"""Exercise actual inheritance of Orc/Wolf/Scorpion, plus legacy death arity."""
from pathlib import Path
import argparse
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
for name in ['wolf', 'scorpion', 'orc', 'spider', 'projectile', 'wave', 'slime', 'common']:
    p.add_argument('--'+name+'-baseline', type=Path, required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable, str(ROOT/'tests/build_spider_orc_receipt_fixture.py'), str(out),
               *[v for n in ['orc','spider','projectile','wave','slime','common']
                 for v in ['--'+n+'-baseline',str(getattr(a,n+'_baseline'))]]], check=True)


def fn(source,name):
    m = re.search(r'^func '+re.escape(name)+r'\(',source,re.M)
    assert m,name
    tail = source[m.start():]
    end = re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()+'\n\n'


for parent in ['src/monsters/orc.gd','tests/orc_before.gd']:
    path = out/parent
    path.write_text(path.read_text().replace('func _visual_call(_method):',
        'func _visual_call(_method, _args: Array = []):')+'var combat_authority: Node\n')
for actor in ['wolf','scorpion']:
    old = getattr(a,actor+'_baseline').read_text()
    new = (ROOT/f'src/monsters/{actor}.gd').read_text()
    names = re.findall(r'^func ([^(]+)\(',old,re.M)
    for name in names:
        body = fn(new,name)
        if name == 'take_damage':
            body = fn(new,'_apply_wolf_damage').replace(
                'func _apply_wolf_damage(amount: int, receipt = null, receipt_revision: int = 0) -> void:',
                'func take_damage(amount: int) -> void:').replace(
                '\tsuper._apply_orc_damage(amount, receipt, receipt_revision)', '\tsuper.take_damage(amount)')
        if name == '_begin_death':
            body = fn(new,'_begin_'+actor+'_death').replace('func _begin_'+actor+'_death','func _begin_death').replace('(receipt = null, receipt_revision: int = 0)','()').replace(
                'super._begin_death_with_result(receipt, receipt_revision)','super._begin_death()')
        assert body == fn(old,name),(actor,name)
    print(actor,'original bodies preserved:',len(names))
    fields = '''var followup_target: WeakRef
var followup_timer := 0.0
var attack_damage := 13
'''
    if actor == 'wolf':
        fields += '''var howl_timer := 0.0
var pack_cast_timer := 0.0
var hit_counts: Dictionary = {}
'''
    for label,source in [('before',old),('after',new)]:
        parent = 'src/monsters/orc.gd' if label == 'after' else 'tests/orc_before.gd'
        content = f'extends "res://{parent}"\n'+fields
        methods = ['_begin_death']
        if actor == 'scorpion':methods += ['consume_without_rewards']
        if actor == 'wolf':
            methods += ['take_damage','_visual_call']
        if label == 'after':
            methods += ['supports_damage_receipt','_begin_death_with_result','_begin_'+actor+'_death']
            if actor == 'wolf':methods += ['take_damage_with_result','_apply_wolf_damage']
        content += ''.join(fn(source,n) for n in methods)
        path = out/(f'src/monsters/{actor}.gd' if label == 'after' else f'tests/{actor}_before.gd')
        path.write_text(content)
    (out/f'tests/{actor}_derived.gd').write_text(
        f'extends "res://src/monsters/{actor}.gd"\nfunc take_damage(_amount):\n\tcurrent_hp -= 1\n')
    smoke = (out/'tests/orc_receipt_smoke.gd').read_text().replace(
        'orc_before',actor+'_before').replace('src/monsters/orc.gd',f'src/monsters/{actor}.gd').replace(
        'orc_derived',actor+'_derived').replace('orc receipt',actor+' receipt')
    wave = (out/'tests/orc_wave_receipt_smoke.gd').read_text().replace(
        'src/monsters/orc.gd',f'src/monsters/{actor}.gd')
    (out/f'tests/{actor}_receipt_smoke.gd').write_text(smoke)
    (out/f'tests/{actor}_wave_receipt_smoke.gd').write_text(wave)
    (out/f'tests/{actor}_wave_helper.gd').write_text(
        wave.replace('extends SceneTree','extends RefCounted\nvar root: Node\nfunc quit(_code):pass'))
# Real modified thrower body/death + existing shared header. No derived actor rewrite.
header = (out/'src/monsters/orc.gd').read_text().split('func take_damage(')[0]
thrower = (ROOT/'src/monsters/goblin_thrower.gd').read_text()
(out/'src/monsters/goblin_thrower.gd').write_text(header+''.join(fn(thrower,n) for n in
    ['take_damage','supports_damage_receipt','take_damage_with_result','_apply_goblin_thrower_damage','_begin_death','_begin_death_with_result','_begin_thrower_standard_death']))
for actor in ['orc','goblin_thrower']:
    (out/f'tests/{actor}_legacy_death.gd').write_text(
        f'extends "res://src/monsters/{actor}.gd"\nvar death_calls := 0\nfunc _begin_death():\n\tdeath_calls += 1\n\tdying = true\n')
(out/'tests/inherited_damage_receipt_smoke.gd').write_text(
    (ROOT/'tests/inherited_damage_receipt_smoke.gd').read_text())
