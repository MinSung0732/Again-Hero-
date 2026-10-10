"""Combine real projectile lifecycle with real slime damage/common/receipt slices."""
from pathlib import Path
import argparse,re,subprocess,sys,shutil
from wave_receipt_source import without_wave_receipt
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--projectile-baseline',type=Path,required=True);p.add_argument('--wave-baseline',type=Path,required=True);p.add_argument('--slime-baseline',type=Path,required=True);p.add_argument('--common-baseline',type=Path,required=True);a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use temporary fixture outside checkout')
def fn(s,n):
 m=re.search(r'^func '+n+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail)
 return (tail[:end.start()] if end else tail).rstrip()
old=a.projectile_baseline.read_text();new=(ROOT/'src/hero/archmage_skill_projectile.gd').read_text();names=re.findall(r'^func ([^(]+)\(',old,re.M)
for n in names:assert fn(old,n)==without_wave_receipt(fn(new,n)),n
print('Current projectile original bodies preserved:',len(names))
subprocess.run([sys.executable,str(ROOT/'tests/build_slime_receipt_fixture.py'),str(out),'--slime-baseline',str(a.slime_baseline),'--common-baseline',str(a.common_baseline)],check=True)
subprocess.run([sys.executable,str(ROOT/'tests/build_wave_projectile_fixture.py'),str(out),'--baseline-file',str(a.wave_baseline)],check=True)
shutil.copy2(ROOT/'tests/wave_receipt_smoke.gd',out/'tests/wave_receipt_smoke.gd')
