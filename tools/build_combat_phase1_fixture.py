"""Production logic; explicit stage9 presentation substitutes, no gameplay rewrites."""
from pathlib import Path
import subprocess,sys,shutil
from PIL import Image
repo=Path(__file__).resolve().parents[1];out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_summon_fixture.py'),str(out)],check=True)
base=Path('assets/art/heroes/stage9_prist/frames')
created=[]
for folder in [base]+[base/f'effect{i}' for i in range(1,8)]:
    for prefix in ['idle','walk','atk','hit','dead','attack','death','cast','frame','effect','projectile','summon']:
        for index in range(1,25):
            rel=folder/f'{prefix}_{index:02d}.png';dest=out/rel
            if not dest.exists():
                dest.parent.mkdir(parents=True,exist_ok=True)
                Image.new('RGBA',(32,32),(100,120,150,255)).save(dest);created.append(str(rel))
(out/'phase1_placeholder_art.txt').write_text('\n'.join(created)+'\n')
source=repo/'tests/fixtures/combat_phase1/battle_spatial.gd.txt'
shutil.copy2(source,out/'tests/combat_phase1_spatial_before.gd')
print('Stage9 explicit presentation substitutes:',len(created))
