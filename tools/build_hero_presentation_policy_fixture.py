"""Run actual visual/UI owners before/after; synthetic textures and external services adapted."""
from pathlib import Path
import argparse,re,subprocess,shutil
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);p.add_argument('--baseline',required=True);a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents:raise SystemExit('Use directory outside repository')
out.mkdir(parents=True,exist_ok=True)
def old(path):return subprocess.check_output(['git','show',a.baseline+':'+path],cwd=repo,text=True)
def method(text,name):
 m=re.search(r'^func '+re.escape(name)+r'\(',text,re.M);assert m,name
 n=re.search(r'^(?:(?:static )?func |const |var |signal |enum |class |@onready |@export)',text[m.end():],re.M)
 return text[m.start():m.end()+n.start() if n else len(text)].rstrip()+'\n'
hero_before=old('src/hero/hero.gd');hero_after=(repo/'src/hero/hero.gd').read_text()
main_before=old('src/main/main.gd');main_after=(repo/'src/main/main.gd').read_text()
for label,before,after,changed in [('Hero',hero_before,hero_after,'_apply_profile_visual'),('Main',main_before,main_after,'_refresh_hero_info_panel')]:
 count=0
 for name in re.findall(r'^func (\w+)\(',before,re.M):
  if name!=changed:assert method(before,name)==method(after,name),name;count+=1
 print(label,'untouched methods identical:',count)
# Reset commands and main owner outside the ability block must remain exact.
assert method(hero_before,'_apply_profile_visual').split('\tif hero_archetype')[0]==method(hero_after,'_apply_profile_visual').split('\tvar profile :=')[0]
left=method(main_before,'_refresh_hero_info_panel');start=left.index('\tvar ability_lines:');end=left.index('\n\tvar build_counts:',start);left=left[:start]+'\t# ability binding\n'+left[end:]
right=method(main_after,'_refresh_hero_info_panel');start=right.index('\thero_info_abilities.text');end=right.index('\n\tvar build_counts:',start);right=right[:start]+'\t# ability binding\n'+right[end:];assert left==right
(out/'src/data').mkdir(parents=True,exist_ok=True);shutil.copy2(repo/'src/data/hero_presentation_catalog.gd',out/'src/data/hero_presentation_catalog.gd')
header='''extends Node2D
const HERO_PRESENTATION=preload("res://src/data/hero_presentation_catalog.gd")
var hero_id:String=""
var hero_archetype:String=""
var sprite_frame_dir:String=""
var hero_sprite:AnimatedSprite2D
var events=[]
var paths=[]
var missing_request=-1
func _init():
 hero_sprite=AnimatedSprite2D.new();add_child(hero_sprite)
 hero_sprite.modulate=Color.RED;hero_sprite.rotation=0.5;hero_sprite.offset=Vector2(9,7)
 hero_sprite.scale=Vector2(3,3);hero_sprite.z_index=9;hero_sprite.show_behind_parent=true
 hero_sprite.speed_scale=1.75
func _load_stage1_texture(path:String) -> Texture2D:
 paths.append(path)
 if paths.size()==missing_request:return null
 var texture=ImageTexture.create_from_image(Image.create(2,2,false,Image.FORMAT_RGBA8))
 texture.set_meta("fixture_path",path)
 return texture
func _apply_normalized_hero_visual_scale():
 events.append(["scale",hero_sprite.z_index,hero_sprite.show_behind_parent])
 hero_sprite.scale=Vector2(2,2)
func _build_stage9_frame_anchor_cache():events.append(["cache9",hero_sprite.z_index,hero_sprite.show_behind_parent])
func _apply_stage9_sprite_anchor():events.append("anchor9");hero_sprite.offset=Vector2(1,9)
func _apply_stage8_sprite_anchor():events.append("anchor8");hero_sprite.offset=Vector2(1,8)
func _apply_stage7_sprite_anchor():events.append("anchor7");hero_sprite.offset=Vector2(1,7)
func _apply_alchemist_philosopher_effect_visuals():events.append(["philosopher",hero_sprite.animation,hero_sprite.speed_scale,hero_sprite.is_playing()])
'''
for label,source in [('before',hero_before),('after',hero_after)]:
 s=re.sub(r'^ +',lambda m:'\t'*len(m.group()),header,flags=re.M)
 for n in range(1,11):s+=re.search(r'^const STAGE'+str(n)+r'_FRAME_DIR := .*$',source,re.M).group()+'\n'
 names=['_apply_profile_visual','_add_named_sequence_animation']
 if label=='after':names+=['_configure_profile_animation','_add_profile_indexed_animation']
 for name in names:s+='\n'+method(source,name)
 (out/(label+'.gd')).write_text(s)
ui='''extends Node
const HERO_PRESENTATION=preload("res://src/data/hero_presentation_catalog.gd")
var battle
var events=[]
var hero_info_name=Label.new()
var hero_info_portrait=TextureRect.new()
var hero_info_stats=Label.new()
var hero_info_abilities=Label.new()
var hero_info_build=Label.new()
var hero_info_ai=Label.new()
class HERO_AUGMENTS:
 static func get_augment(id) -> Dictionary:return {"name":"fixture_"+id,"max_stack":2}
 static func get_effective_max_stack(_id,_archetype,max_stack) -> int:return max_stack
class Battle extends Node:
 var snapshot={}
 var fallback=false
 var reads=[]
 func get_hero_info_hud():reads.append("hud");return {} if fallback else snapshot
 func get_snapshot():reads.append("snapshot");return snapshot
func _load_normalized_hero_portrait(path):events.append(path);return null
func _init():
 for control in [hero_info_name,hero_info_portrait,hero_info_stats,hero_info_abilities,hero_info_build,hero_info_ai]:add_child(control)
 battle=Battle.new();add_child(battle)
'''
for label,source in [('before',main_before),('after',main_after)]:
 s=re.sub(r'^ +',lambda m:'\t'*len(m.group()),ui,flags=re.M)+'\n'+method(source,'_refresh_hero_info_panel')
 (out/('ui_'+label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/hero_presentation_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="HeroPresentationPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
