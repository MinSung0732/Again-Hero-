"""Real Battle/Hero/item bounds and pickup logic; placeholder artwork only."""
from pathlib import Path
import argparse,subprocess,sys
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[1];out=a.destination.resolve()
subprocess.run([sys.executable,str(r/'tools/build_online_fixture.py'),str(out)],check=True)
for folder,prefix,count in [('heroes/item/heal_frames','float',4),('heroes/item/magunet_frames','magnet',4),('heroes/item/box_frames','expbox',8),('effects/expstone/01_normal','frame',6)]:
 for i in range(1,count+1):
  path=out/'assets/art'/folder/('%s_%02d.png'%(prefix,i))
  if not path.exists():
   path.parent.mkdir(parents=True,exist_ok=True);Image.new('RGBA',(64,64),'white').save(path)
print('Dynamic pickup textures supplied as fixture-only placeholders.')
