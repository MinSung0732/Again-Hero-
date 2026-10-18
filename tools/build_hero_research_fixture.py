"""Real weapon runtime, research data and exact native shield layer/helper."""
from pathlib import Path
import subprocess,sys
repo=Path(__file__).resolve().parents[1];out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/hero_research_runtime_smoke.gd'],check=True)
s=(repo/'src/hero/hero.gd').read_text()
def method(n):
 a=s.index('func '+n+'(');b=s.find('\nfunc ',a+1);return s[a:b if b>=0 else len(s)]+'\n'
(out/'tests/hero_research_shield_harness.gd').write_text('''extends Node2D
var player_controlled := true
var player_weapons
var max_hp := 1000
var shield_hp := 0.0
var shield_max_hp := 0.0
var purifier_protection_config := {"shield_hp_ratio_per_tick":0.01}
'''+method('_player_shield_amount')+method('_add_purifier_shield_layer'))
