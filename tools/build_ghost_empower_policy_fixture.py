"""Extract the actual before/after ghost callback; actor refresh is an adapter."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('destination', type=Path)
parser.add_argument('--baseline', required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
out = args.destination.resolve()
if out == repo or repo in out.parents:
    raise SystemExit('Use directory outside repository')
out.mkdir(parents=True, exist_ok=True)

def old(path):
    return subprocess.check_output(['git', 'show', args.baseline + ':' + path], cwd=repo, text=True)

def method(text, name):
    match = re.search(r'^func ' + re.escape(name) + r'\(', text, re.M)
    assert match, name
    following = re.search(r'^func ', text[match.end():], re.M)
    return text[match.start():match.end() + following.start() if following else len(text)].rstrip() + '\n'

before = old('src/battle/battle.gd')
after = (repo / 'src/battle/battle.gd').read_text()
count = 0
for name in re.findall(r'^func (\w+)\(', before, re.M):
    if name not in ['_apply_ghost_death_empower', '_apply_pre_reward_death_reactions']:
        assert method(before, name) == method(after, name), name
        count += 1
assert method(before, '_apply_pre_reward_death_reactions').replace('call(callback, monster)', 'call(callback, monster, profile)') == method(after, '_apply_pre_reward_death_reactions')
for text in [before, after]:
    fn = method(text, '_apply_ghost_death_empower')
    selection = fn[fn.index('\tghost_death_buff_candidates.clear()'):fn.index('\tvar multiplier :=')]
    refresh = fn[fn.index('\t_apply_normal_augments_to_existing_monster('):]
    if text == before:
        original_selection, original_refresh = selection, refresh
    else:
        assert selection == original_selection and refresh == original_refresh
print('Untouched Battle methods identical:', count, '; selection/refresh and dispatcher ordering identical')
queue = ['src/data/monster_catalog.gd']
seen = set()
while queue:
    path = queue.pop()
    if path in seen:
        continue
    seen.add(path)
    source = (repo / path).read_text()
    queue += re.findall(r'preload\("res://([^"\n]+\.gd)"\)', source)
    dest = out / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)', 'null', source))
source = old('src/data/monster_catalog.gd').replace('class_name MonsterCatalog', '')
(out / 'catalog_before.gd').write_text(re.sub(r'preload\("res://[^"\n]+\.tscn"\)', 'null', source))
header = '''extends Node
const MONSTER_CATALOG=preload("res://src/data/monster_catalog.gd")
var active_monsters={}
var ghost_death_buff_candidates=[]
var configs={}
var events=[]
class Actor extends Node:
 var current_hp=10
 var monster_type="fixture"
func _get_special_augment_config(id) -> Dictionary:
 events.append(["config",String(id)])
 return configs.get(id,{})
func _apply_normal_augments_to_existing_monster(actor,id):
 events.append(["refresh",actor.name,id,actor.get_meta("ghost_death_empower_stacks",0)])
'''
for label, text in [('before', before), ('after', after)]:
    source = re.sub(r'^ +', lambda match: '\t' * len(match.group()), header, flags=re.M)
    source += '\n' + method(text, '_apply_ghost_death_empower')
    source += '\nfunc invoke(actor,profile):\n\t_apply_ghost_death_empower(actor' + (',profile' if label == 'after' else '') + ')\n'
    (out / (label + '.gd')).write_text(source)
shutil.copy2(repo / 'tests/ghost_empower_policy_smoke.gd', out / 'smoke.gd')
(out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="GhostEmpowerPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
print('Actual Catalog dependencies:', len(seen), '; scene references null')
