"""Swap only an isolated fixture helper, restore it even if a replay fails."""
from pathlib import Path
import argparse, subprocess, re, json
p=argparse.ArgumentParser();p.add_argument('fixture',type=Path);p.add_argument('godot');p.add_argument('--output',type=Path,required=True);args=p.parse_args()
repo=Path(__file__).resolve().parents[1];fixture=args.fixture.resolve()
if fixture==repo or repo in fixture.parents or not (fixture/'phase1_placeholder_art.txt').exists():raise SystemExit('Requires isolated combat fixture')
helper=fixture/'src/systems/monster_hit_context.gd';saved=helper.read_bytes();rows=[]
try:
 for mode,content in [('before',(repo/'tests/fixtures/combat_phase2/monster_hit_context_before.gd.txt').read_bytes()),('after',(repo/'src/systems/monster_hit_context.gd').read_bytes())]:
  helper.write_bytes(content)
  result=subprocess.run([args.godot,'--headless','--path',str(fixture),'--script','res://tests/combat_phase2_weapon_replay.gd'],capture_output=True,text=True,timeout=240)
  log=result.stdout+result.stderr;args.output.parent.mkdir(parents=True,exist_ok=True);args.output.with_name('weapon_replay_'+mode+'.log').write_text(log)
  if result.returncode or 'SCRIPT ERROR' in log or 'ERROR:' in log:raise SystemExit(mode+' replay runtime error; see log')
  match=re.search(r'PHASE2_WEAPON_REPLAY scenarios=(\d+) frames=(\d+) sha256=([a-f0-9]+)',log)
  if not match:raise SystemExit('Missing replay result')
  rows.append(dict(mode=mode,scenarios=int(match[1]),frames=int(match[2]),sha256=match[3]))
finally:helper.write_bytes(saved)
passed=rows[0]['sha256']==rows[1]['sha256'] and rows[0]['scenarios']==300
args.output.write_text(json.dumps(dict(passed=passed,rows=rows,scope='100 weapons x Lv1/Lv10/MAX; mock targets, HP/heal/shield/RNG every tick'),indent=2)+'\n')
print(args.output.read_text())
if not passed:raise SystemExit(1)
