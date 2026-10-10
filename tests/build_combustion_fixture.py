"""Extract actual combustion/damage/FX functions and actual battle transient pool."""
from pathlib import Path
import argparse,re,shutil
from fire_skill_source import without_fire_skill_guards
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('target',type=Path);p.add_argument('--baseline-file',type=Path,required=True);a=p.parse_args();out=a.target.resolve()
if out==ROOT or ROOT in out.parents:raise SystemExit('Use a temporary fixture outside checkout')
before=a.baseline_file.read_text();after=(ROOT/'src/hero/hero.gd').read_text()
def function(s,name):
 m=re.search(r'^func '+name+r'\(',s,re.M);tail=s[m.start():];end=re.search(r'\nfunc ',tail)
 return (tail[:end.start()] if end else tail).rstrip()+'\n\n'
names=re.findall(r'^func ([^(]+)\(',before,re.M)
for name in names:assert function(before,name)==without_fire_skill_guards(function(after,name)),name
print('Original Hero method comparison:',len(names))
out.mkdir(parents=True,exist_ok=True);(out/'project.godot').write_text('[application]\nconfig/name="Combustion lifetime fixture"\n')
for path in ['src/systems/battle_entity_registry.gd','tests/combustion_lifetime_smoke.gd']:
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,dest)
header='''extends Node2D
var current_hp := 100
var attack_damage := 100
var target: Node2D
var hero_sprite := Sprite2D.new()
var archmage_casting_sequence_count := 0
var archmage_casting_sequence := false
var archmage_combustion_charge_audio := "charge"
var archmage_combustion_release_audio := "release"
var _archmage_fx_frames_cache: Dictionary = {}
var _combat_monster_scratch: Array = []
var candidates: Array = []
var nearest: Node2D
var effects: Array = []
var audio: Array = []
var charge_fx: AnimatedSprite2D
var test_texture: Texture2D
class Policy:
    static func is_detectable(node: Node) -> bool:
        return is_instance_valid(node) and not node.is_queued_for_deletion() and node.current_hp > 0
const HERO_TARGET_POLICY = Policy
func _init():
    add_child(hero_sprite)
    test_texture = ImageTexture.create_from_image(Image.create(2,2,false,Image.FORMAT_RGBA8))
func _skill_damage_multiplier(empowered: bool) -> float: return 1.5 if empowered else 1.0
func _load_stage1_texture(_path: String) -> Texture2D: return test_texture
func _ensure_archmage_audio_runtime(): pass
func _play_archmage_player(player): audio.append(player)
func _find_nearest_monster_from_point(_position: Vector2) -> Node2D: return nearest
func _fill_monster_nodes_near(_position, _radius, result):
    result.clear()
    result.append_array(candidates)
func _fill_monster_nodes_in_rect(_rect, result):
    result.clear()
    result.append_array(candidates)
func _spawn_archmage_fx(dir: String, prefix: String, start: int, count: int, fps: float, looped: bool, world_position: Vector2, fx_scale: Vector2) -> AnimatedSprite2D:
    effects.append([dir,prefix,start,count,fps,looped,world_position,fx_scale])
    var fx = _spawn_archmage_fx_actual(dir,prefix,start,count,fps,looped,world_position,fx_scale)
    if looped: charge_fx = fx
    return fx
'''
methods=['_cast_archmage_combustion','_damage_monsters_in_radius','_damage_monsters_in_corridor','_begin_archmage_casting_sequence','_end_archmage_casting_sequence','_capture_delayed_skill_source','_is_delayed_skill_life_current','_is_delayed_skill_source_current','_recycle_archmage_fx']
for label,source in [('before',before),('after',after)]:
 extra=['_recycle_archmage_fx_if_current'] if label=='after' else []
 spawn=function(source,'_spawn_archmage_fx').replace('func _spawn_archmage_fx(', 'func _spawn_archmage_fx_actual(',1)
 (out/'tests'/('fire_'+label+'.gd')).write_text(header.replace('    ','\t')+spawn+''.join(function(source,n) for n in methods+extra))
battle=(ROOT/'src/battle/battle.gd').read_text()
scope='''extends Node2D
const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
const MAX_TRANSIENT_FX_POOL_PER_TYPE := 600
var registry = REGISTRY.new()
var transient_fx_pools: Dictionary = {}
func get_battle_entity_handle(node: Node) -> Vector3i: return registry.get_handle(node)
func resolve_battle_entity(handle: Vector3i) -> Node: return registry.resolve(handle)
'''
(out/'tests/scope.gd').write_text(scope+function(battle,'acquire_transient_fx')+function(battle,'recycle_transient_fx'))
