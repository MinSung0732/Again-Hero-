"""Actual normalization/channel setup/completion and visual owner before/after."""
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
before=old('src/hero/hero.gd');after=(repo/'src/hero/hero.gd').read_text()
changed=['_apply_normalized_hero_visual_scale','_on_fighter_guard_release_effect_finished','_apply_stage6_berserker_effect_visuals','_apply_alchemist_philosopher_effect_visuals'];count=0
for name in re.findall(r'^func (\w+)\(',before,re.M):
 if name not in changed:assert method(before,name)==method(after,name),name;count+=1
assert old('src/main/main.gd')==(repo/'src/main/main.gd').read_text()
assert old('src/battle/battle.gd')==(repo/'src/battle/battle.gd').read_text()
catalog=(repo/'src/data/hero_presentation_catalog.gd').read_text();assert catalog.startswith(old('src/data/hero_presentation_catalog.gd'))
print('Other Hero methods identical:',count,'; Main/Battle and existing presentation data identical')
(out/'src/data').mkdir(parents=True,exist_ok=True);(out/'src/data/hero_presentation_catalog.gd').write_text(catalog)
header='''extends Node2D
const HERO_PRESENTATION=preload("res://src/data/hero_presentation_catalog.gd")
var hero_id:String="other"
var hero_archetype:String="unknown"
var sprite_frame_dir:String=""
var hero_sprite:AnimatedSprite2D
var channel_effect:AnimatedSprite2D
var alchemist_philosopher_config:Dictionary={}
var paths=[]
var signals_seen=[]
var anchors=[]
var textures={}
var missing_requests=[]
var missing_all=false
var reference_texture:Texture2D
func image_texture(height:int,width:int=64,canvas:int=128) -> ImageTexture:
 var img=Image.create(width,canvas,false,Image.FORMAT_RGBA8)
 if height>0:img.fill_rect(Rect2i(4,0,8,height),Color.WHITE)
 return ImageTexture.create_from_image(img)
func _init():
 hero_sprite=AnimatedSprite2D.new();add_child(hero_sprite)
 channel_effect=AnimatedSprite2D.new();add_child(channel_effect)
 var old=SpriteFrames.new()
 for name in ["madness","philosopher_stone","cylinder_dust","other"]:
  old.add_animation(name)
  for _i in range(3):
   var texture=image_texture(4);texture.set_meta("fixture_path","old");old.add_frame(name,texture)
 channel_effect.sprite_frames=old;channel_effect.play("other");channel_effect.frame=2;channel_effect.frame_progress=0.3
 channel_effect.visible=true;channel_effect.position=Vector2(13,17);channel_effect.offset=Vector2(5,7)
 channel_effect.scale=Vector2(3,4);channel_effect.modulate=Color(0.2,0.3,0.4,0.5);channel_effect.rotation=0.4;channel_effect.z_index=7
 channel_effect.speed_scale=1.5
 channel_effect.animation_changed.connect(func():record_signal("animation"))
 channel_effect.sprite_frames_changed.connect(func():record_signal("frames"))
 channel_effect.frame_changed.connect(func():record_signal("frame"))
func record_signal(kind):signals_seen.append([kind,channel_effect.animation,channel_effect.frame,channel_effect.is_playing(),channel_effect.position,channel_effect.modulate])
func _load_stage1_texture(path:String) -> Texture2D:
 paths.append(path)
 if path==HERO_REFERENCE_SHEET_PATH:return reference_texture
 if missing_all or paths.size() in missing_requests:return null
 if not textures.has(path):
  var texture=image_texture(36);texture.set_meta("fixture_path",path);textures[path]=texture
 return textures[path]
func _build_stage9_frame_anchor_cache():anchors.append("cache9")
func _apply_stage9_sprite_anchor():anchors.append("anchor9");hero_sprite.offset=Vector2(1,9)
func _apply_stage8_sprite_anchor():anchors.append("anchor8");hero_sprite.offset=Vector2(1,8)
func _apply_stage7_sprite_anchor():anchors.append("anchor7");hero_sprite.offset=Vector2(1,7)
'''
for label,source in [('before',before),('after',after)]:
 s=re.sub(r'^ +',lambda m:'\t'*len(m.group()),header,flags=re.M)
 names=['STAGE%d_FRAME_DIR'%n for n in range(1,11)]+['HERO_REFERENCE_SHEET_PATH','HERO_REFERENCE_FRAME_SIZE','HERO_REFERENCE_RENDER_SCALE','STAGE1_TARGET_VISIBLE_HEIGHT']
 for name in names:s+=re.search(r'^const '+name+r' := .*$',source,re.M).group()+'\n'
 names=changed+['_get_stage1_reference_render_height','_apply_profile_visual','_configure_profile_animation','_add_profile_indexed_animation','_add_named_sequence_animation']
 if label=='after':names+=['_configure_channel_effect_profile']
 for name in names:s+='\n'+method(source,name)
 (out/(label+'.gd')).write_text(s)
shutil.copy2(repo/'tests/hero_effect_policy_smoke.gd',out/'smoke.gd')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="HeroEffectPolicyFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
