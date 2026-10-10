"""Run actual projectile code before/after; replace only rendering and detection policy.

No damage/setup/physics/finish/timer method is replaced. Source queries are in-memory
spies and body_entered calls are explicit; this is not a real collision scene.
"""
from pathlib import Path
import argparse
import re
import shutil
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('target', type=Path)
p.add_argument('--baseline-file', type=Path, required=True)
a = p.parse_args()
out = a.target.resolve()
if out == ROOT or ROOT in out.parents:
    raise SystemExit('Use temporary fixture outside checkout')
before = a.baseline_file.read_text()
after = (ROOT/'src/hero/archmage_skill_projectile.gd').read_text()
def function(s, name):
    m = re.search(r'^func '+re.escape(name)+r'\(',s,re.M)
    tail = s[m.start():]
    end = re.search(r'\nfunc ',tail)
    return (tail[:end.start()] if end else tail).rstrip()
allowed = {'setup','_physics_process','_on_body_entered','_finish_after_chain_ticks',
           '_apply_chain_current_ticks','_damage_monsters_along_segment','_finish','deactivate_for_pool'}
names = re.findall(r'^func ([^(]+)\(', before, re.M)
for name in names:
    if name not in allowed:
        assert function(before,name) == function(after,name), name
print('Untouched projectile bodies identical:',len(names)-len(allowed))
out.mkdir(parents=True, exist_ok=True)
(out/'project.godot').write_text('[application]\nconfig/name="Chain projectile lifetime fixture"\n')
for path in ['src/systems/battle_entity_registry.gd','src/systems/battle_target_reference.gd',
             'tests/chain_projectile_lifetime_smoke.gd','src/hero/archmage_skill_projectile.gd']:
    dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,dest)
(out/'src/systems/hero_target_policy.gd').write_text('''extends RefCounted
static func is_detectable(node: Node) -> bool:
	return is_instance_valid(node) and not node.is_queued_for_deletion() and bool(node.get_meta("detectable", true))
''')
for variant, source in [('before',before),('after',after)]:
    for name,body in {
        '_reset_visual_state':'\tsprite.visible = false\n\ttail.visible = false',
        '_apply_visual':'\trotation = direction.angle()',
        '_spawn_hit_animation':'\tpass', '_build_frames':'\treturn null',
    }.items():
        original=function(source,name)
        signature=original[:original.index(' -> ')+original[original.index(' -> '):].index(':')+1]
        source=source.replace(original,signature+'\n'+body)
    dest=out/f'tests/chain_projectile_{variant}.gd';dest.write_text(source)
print('Fixture created:',out)
