extends Node
signal hero_outcome_confirmed(outcome: StringName)
signal battle_finished(message: String, player_won: bool)
const HERO_SURVIVAL := {"DURATION": 900.0}
class Stages:
	static func get_stage(_id: String) -> Dictionary: return {}
class Progress:
	static func complete_hard_stage(_id: String) -> Dictionary: return {"success": true}
	static func complete_stage(_id, _number, _next, _next_number, _reward) -> Dictionary: return {"success": true}
const STAGE_CATALOG = Stages
const STAGE_PROGRESS = Progress
class Registry:
	func retire_instance(_id): pass
class Flow:
	func reset(): pass
class Hero extends Node2D:
	var current_hp := 0
var hero: Node2D
var current_hero_profile := {"id": "ranged_rookie", "display_name": "fixture"}
var current_stage_data := {"number": 1}
var current_stage_id := "stage_1"
var campaign_difficulty := "easy"
var battle_over := false
var online_match_mode := false
var practice_mode := false
var tutorial_mode := false
var hero_player_mode := false
var _mission_service = null
var flow_pause_manager := Flow.new()
var battle_entity_registry := Registry.new()
var demon_augment_selection_active := true
var _run_reward_save_failed := false
var run_metrics := {"elapsed_seconds": 900.0}
var pause_syncs := 0
func _init():
	hero = Hero.new(); add_child(hero)
func _sync_combat_pause_state(): pause_syncs += 1
func _emit_stats(_hp): pass
func _grant_run_research_reward(_clear) -> String: return ""
