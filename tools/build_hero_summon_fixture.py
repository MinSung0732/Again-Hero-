"""Real stage8 Hero/summon logic with explicit placeholder presentation only."""
from pathlib import Path
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable, str(ROOT/'tools/build_hero_max_fixture.py'), str(out)], check=True)
base = Path('assets/art/heroes/stage8_summoner/frames')
created = []
for folder in [base] + [base/f'effect{i}' for i in range(1, 6)]:
    for prefix in ['idle', 'walk', 'atk', 'hit', 'dead', 'move', 'attack', 'death', 'summon', 'projectile']:
        for index in range(1, 25):
            relative = folder/f'{prefix}_{index:02d}.png'
            target = out/relative
            if target.exists():
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            Image.new('RGBA', (32, 32), (80, 180, 170, 255)).save(target)
            created.append(str(relative))
(out/'summon_placeholder_art.txt').write_text('\n'.join(created)+'\n')
print('Stage8 fixture presentation placeholders:', len(created), '(no production art edits)')
