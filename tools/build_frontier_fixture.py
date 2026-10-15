"""Real new-monster art/logic over the existing asset-light Battle fixture."""
from pathlib import Path
import argparse, subprocess, sys, shutil, re, json
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[1];out=a.destination.resolve()
subprocess.run([sys.executable,str(r/'tools/build_online_fixture.py'),str(out)],check=True)
s=(r/'src/data/monster_catalog.gd').read_text()
s=re.sub(r'preload\("res://src/monsters/([^"/]+)\.tscn"\)',lambda m:m[0] if m[1] in {'Slime','Spider','Orc','BombRat','SkeletonArcher'} or m[1].startswith('Frontier') else 'null',s)
(out/'src/data/monster_catalog.gd').write_text(s)
text=(r/'src/data/frontier_monster_catalog.gd').read_text();definitions=json.JSONDecoder().raw_decode(text.split('const DEFINITIONS := ',1)[1])[0]
for d in definitions.values():
 for key in ['normal_visual','elite_visual']:
  relative=Path(d[key]['asset_dir'].removeprefix('res://'))
  if not (r/relative).is_dir():raise SystemExit('Missing real art folder: '+str(relative))
  shutil.copytree(r/relative,out/relative,dirs_exist_ok=True)
(out/'tools').mkdir(exist_ok=True)
for name in ['monster_balance_audit.gd','pack_frontier_art_fixture.gd']:
 shutil.copyfile(r/'tools'/name,out/'tools'/name)
print('Real 8-species normal/elite frames copied; other missing presentation is fixture-only.')
