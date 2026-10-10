"""Real registry/observation and extracted battle adapter; exact original body checks."""
from pathlib import Path
import argparse,re,shutil
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--registry-baseline',type=Path,required=True);p.add_argument('--battle-baseline',type=Path,required=True);a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
def fn(s,n):
 m=re.search(r'^func '+n+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail)
 return (tail[:end.start()] if end else tail).rstrip()
for path,baseline in [('src/systems/battle_entity_registry.gd',a.registry_baseline),('src/battle/battle.gd',a.battle_baseline)]:
 old=baseline.read_text();new=(ROOT/path).read_text();names=re.findall(r'^func ([^(]+)\(',old,re.M)
 for n in names:
  body=fn(new,n)
  if n=='activate' and 'registry' in path:
   hook='\tvar handle := Vector3i(_epoch, slot + 1, _generations[slot])\n\tnode.set_meta(LAST_LIFE_META, handle)\n\treturn handle'
   assert body.count(hook)==1
   body=body.replace(hook,'\treturn Vector3i(_epoch, slot + 1, _generations[slot])')
  assert fn(old,n)==body,(path,n)
 print('Original functions preserved:',path,len(names))
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Damage observation fixture"\n')
for path in ['src/systems/battle_entity_registry.gd','src/systems/battle_damage_observation.gd','tests/damage_observation_smoke.gd','tests/battle_entity_registry_smoke.gd']:
 d=out/path;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,d)
source=(ROOT/'src/battle/battle.gd').read_text()
(out/'tests/authority.gd').write_text('extends Node\nconst REGISTRY := preload("res://src/systems/battle_entity_registry.gd")\nvar battle_entity_registry = REGISTRY.new()\n'+ '\n\n'.join(fn(source,n) for n in ['get_battle_entity_handle','resolve_battle_entity','get_last_battle_entity_handle'])+'\n')
