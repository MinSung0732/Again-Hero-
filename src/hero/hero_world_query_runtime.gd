extends RefCounted
class_name HeroWorldQueryRuntime

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")
const BATTLE_SCOPE := preload("res://src/systems/battle_scope.gd")

var owner: Node

var monster_nodes_cache: Array = []
var monster_nodes_cache_revision: int = -1
var monster_nodes_cache_process_frame: int = -1
var monster_nodes_cache_physics_frame: int = -1
var aux_group_nodes_cache: Dictionary = {}
var aux_group_nodes_filled: Dictionary = {}
var aux_group_nodes_cache_process_frame: int = -1
var aux_group_nodes_cache_physics_frame: int = -1


func _init(new_owner: Node) -> void:
	owner = new_owner


func get_monster_nodes_cached() -> Array:
	if not is_instance_valid(owner):
		return []

	var process_frame := Engine.get_process_frames()
	var physics_frame := Engine.get_physics_frames()
	if (
		process_frame != monster_nodes_cache_process_frame
		or physics_frame != monster_nodes_cache_physics_frame
		or monster_nodes_cache_revision != HERO_TARGET_POLICY.revision
	):
		var tree := owner.get_tree()
		if tree == null:
			monster_nodes_cache = []
		else:
			var battle := owner.get_parent()
			if is_instance_valid(battle) and battle.has_method("fill_active_monsters"):
				battle.call("fill_active_monsters", monster_nodes_cache)
			else:
				monster_nodes_cache = tree.get_nodes_in_group("monsters")
			HERO_TARGET_POLICY.filter_detectable(monster_nodes_cache)
		monster_nodes_cache_process_frame = process_frame
		monster_nodes_cache_physics_frame = physics_frame
		monster_nodes_cache_revision = HERO_TARGET_POLICY.revision
	return monster_nodes_cache


func get_aux_group_nodes_cached(group_name: StringName) -> Array:
	if not is_instance_valid(owner):
		return []

	var process_frame := Engine.get_process_frames()
	var physics_frame := Engine.get_physics_frames()
	if (
		process_frame != aux_group_nodes_cache_process_frame
		or physics_frame != aux_group_nodes_cache_physics_frame
	):
		aux_group_nodes_filled.clear()
		aux_group_nodes_cache_process_frame = process_frame
		aux_group_nodes_cache_physics_frame = physics_frame

	# One reusable Array per group; refilled at most once per frame.
	var cached = aux_group_nodes_cache.get(group_name)
	if not cached is Array:
		cached = []
		aux_group_nodes_cache[group_name] = cached
	if not aux_group_nodes_filled.has(group_name):
		BATTLE_SCOPE.fill_group(owner, group_name, cached)
		aux_group_nodes_filled[group_name] = true
	return cached


func fill_monster_nodes_near(
	origin: Vector2,
	radius: float,
	result: Array
) -> void:
	result.clear()
	if not is_instance_valid(owner):
		return

	var battle := owner.get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("fill_monsters_near")
	):
		battle.call("fill_monsters_near", origin, radius, result)
		HERO_TARGET_POLICY.filter_detectable(result)
		return

	for node in get_monster_nodes_cached():
		result.append(node)


func get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	var result: Array = []
	fill_monster_nodes_near(origin, radius, result)
	return result


func fill_monster_nodes_in_rect(
	world_rect: Rect2,
	result: Array
) -> void:
	result.clear()
	if not is_instance_valid(owner):
		return

	var battle := owner.get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("fill_monsters_in_rect")
	):
		battle.call("fill_monsters_in_rect", world_rect, result)
		HERO_TARGET_POLICY.filter_detectable(result)
		return

	for node in get_monster_nodes_cached():
		result.append(node)


func get_monster_nodes_in_rect(world_rect: Rect2) -> Array:
	var result: Array = []
	fill_monster_nodes_in_rect(world_rect, result)
	return result
