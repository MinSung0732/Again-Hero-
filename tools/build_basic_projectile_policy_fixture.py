"""Before/after production basic projectile, real hit context, placeholder PNGs."""
from pathlib import Path
import argparse, re, shutil
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline-file',type=Path,required=True);p.add_argument('--without-art',action='store_true');a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents:raise SystemExit('Use a directory outside the repository')
out.mkdir(parents=True,exist_ok=True)
for path in ['src/hero/hero_projectile.gd','src/hero/HeroProjectile.tscn','src/hero/projectile_volley.gd','src/systems/monster_hit_context.gd','src/data/hero_basic_projectile_catalog.gd','tests/basic_projectile_policy_smoke.gd']:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(repo/path,dest)
(out/'tests/basic_projectile_before.gd').write_text(a.baseline_file.read_text())
scene=(repo/'src/hero/HeroProjectile.tscn').read_text()
(out/'tests/BasicBefore.tscn').write_text(scene.replace('res://src/hero/hero_projectile.gd','res://tests/basic_projectile_before.gd'))
for path in ([] if a.without_art else re.findall(r'"res://([^"\n]+\.png)"',(repo/'src/data/hero_basic_projectile_catalog.gd').read_text())):
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);Image.new('RGBA',(32,32),(90,130,180,255)).save(dest)
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="BasicProjectilePolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Actual projectile before/after + hit context;', 0 if a.without_art else 14, 'placeholder PNGs')
