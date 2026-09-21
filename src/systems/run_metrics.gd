extends RefCounted
class_name RunMetrics

const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")

const STRATEGY_WINDOW_SECONDS := 15.0
const STRATEGY_MIN_SPEND := 12.0
const STRATEGY_DOMINANCE_RATIO := 0.60
const STRATEGY_SWITCH_COOLDOWN := 6.0

const RESEARCH_BASE_REWARD := 80
const RESEARCH_DAMAGE_STEP_RATIO := 0.10
const RESEARCH_DAMAGE_STEP_REWARD := 6
const RESEARCH_DAMAGE_MAX := 60
const RESEARCH_TIME_STEP_SECONDS := 60.0
const RESEARCH_TIME_STEP_REWARD := 5
const RESEARCH_TIME_MAX := 30
const RESEARCH_OBSERVATION_REWARD := 4
const RESEARCH_OBSERVATION_MAX := 20
const RESEARCH_TOTAL_MAX := 160

var elapsed_seconds: float = 0.0
var duration_seconds: float = 0.0

var summon_counts: Dictionary = {}
var summon_spend: Dictionary = {}
var monster_death_counts: Dictionary = {}

var lowest_hero_hp: int = 0
var lowest_hero_hp_ratio: float = 1.0

var hero_augment_events: Array = []
var recent_summons: Array = []
var strategy_switches: Array = []

var current_strategy_type: String = ""
var last_strategy_change_time: float = -999.0

func reset(
	new_duration_seconds: float,
	initial_hero_hp: int,
	initial_hero_max_hp: int
) -> void:
	elapsed_seconds = 0.0
	duration_seconds = maxf(new_duration_seconds, 0.0)

	summon_counts.clear()
	summon_spend.clear()
	monster_death_counts.clear()
	hero_augment_events.clear()
	recent_summons.clear()
	strategy_switches.clear()

	current_strategy_type = ""
	last_strategy_change_time = -999.0

	lowest_hero_hp = maxi(initial_hero_hp, 0)
	lowest_hero_hp_ratio = (
		float(initial_hero_hp) / float(maxi(initial_hero_max_hp, 1))
	)

func tick(delta: float) -> void:
	elapsed_seconds += maxf(delta, 0.0)
	_prune_recent_summons()

func is_time_up() -> bool:
	return duration_seconds > 0.0 and elapsed_seconds >= duration_seconds

func get_remaining_seconds() -> float:
	if duration_seconds <= 0.0:
		return 0.0
	return maxf(duration_seconds - elapsed_seconds, 0.0)

func record_summon(monster_type: String, cost: float) -> void:
	if monster_type.is_empty():
		return

	summon_counts[monster_type] = int(summon_counts.get(monster_type, 0)) + 1
	summon_spend[monster_type] = (
		float(summon_spend.get(monster_type, 0.0)) + maxf(cost, 0.0)
	)

	recent_summons.append({
		"time": elapsed_seconds,
		"type": monster_type,
		"weight": maxf(cost, 0.0),
	})
	_update_strategy_state()

func record_monster_death(monster_type: String) -> void:
	if monster_type.is_empty():
		return
	monster_death_counts[monster_type] = (
		int(monster_death_counts.get(monster_type, 0)) + 1
	)

func record_hero_hp(current_hp: int, max_hp: int) -> void:
	var safe_max := maxi(max_hp, 1)
	var safe_hp := clampi(current_hp, 0, safe_max)
	var ratio := float(safe_hp) / float(safe_max)

	if ratio < lowest_hero_hp_ratio:
		lowest_hero_hp_ratio = ratio
		lowest_hero_hp = safe_hp

func record_hero_augment(
	level: int,
	chosen_name: String,
	reason: String
) -> void:
	hero_augment_events.append({
		"time": elapsed_seconds,
		"level": level,
		"name": chosen_name,
		"reason": reason,
	})

func get_research_reward_breakdown() -> Dictionary:
	var damage_ratio := clampf(1.0 - lowest_hero_hp_ratio, 0.0, 1.0)
	var damage_steps := int(floor(
		(damage_ratio + 0.0001) / RESEARCH_DAMAGE_STEP_RATIO
	))
	var damage_reward := mini(
		damage_steps * RESEARCH_DAMAGE_STEP_REWARD,
		RESEARCH_DAMAGE_MAX
	)

	var time_steps := int(floor(
		maxf(elapsed_seconds, 0.0) / RESEARCH_TIME_STEP_SECONDS
	))
	var time_reward := mini(
		time_steps * RESEARCH_TIME_STEP_REWARD,
		RESEARCH_TIME_MAX
	)

	var observation_reward := mini(
		hero_augment_events.size() * RESEARCH_OBSERVATION_REWARD,
		RESEARCH_OBSERVATION_MAX
	)

	var total := mini(
		RESEARCH_BASE_REWARD
		+ damage_reward
		+ time_reward
		+ observation_reward,
		RESEARCH_TOTAL_MAX
	)

	return {
		"base": RESEARCH_BASE_REWARD,
		"damage": damage_reward,
		"time": time_reward,
		"observation": observation_reward,
		"total": total,
		"damage_ratio": damage_ratio,
	}

func get_snapshot() -> Dictionary:
	return {
		"elapsed_seconds": elapsed_seconds,
		"duration_seconds": duration_seconds,
		"remaining_seconds": get_remaining_seconds(),
		"summon_counts": summon_counts.duplicate(true),
		"summon_spend": summon_spend.duplicate(true),
		"monster_death_counts": monster_death_counts.duplicate(true),
		"lowest_hero_hp": lowest_hero_hp,
		"lowest_hero_hp_ratio": lowest_hero_hp_ratio,
		"hero_augment_events": hero_augment_events.duplicate(true),
		"strategy_switches": strategy_switches.duplicate(true),
		"current_strategy_type": current_strategy_type,
	}

func get_result_summary() -> String:
	var lines: PackedStringArray = []
	lines.append("Run %s / 목표 %s" % [
		_format_time(elapsed_seconds),
		_format_time(duration_seconds),
	])
	lines.append("Hero 최저 HP: %d (%.0f%%)" % [
		lowest_hero_hp,
		lowest_hero_hp_ratio * 100.0,
	])

	var summon_parts: PackedStringArray = []
	for monster_type in MONSTER_CATALOG.get_ids():
		var count := int(summon_counts.get(monster_type, 0))
		if count <= 0:
			continue
		summon_parts.append("%s %d" % [
			MONSTER_CATALOG.get_name(monster_type),
			count,
		])
	if summon_parts.is_empty():
		lines.append("직접 소환: 없음")
	else:
		lines.append("직접 소환: %s" % " · ".join(summon_parts))

	if strategy_switches.is_empty():
		if current_strategy_type.is_empty():
			lines.append("전략 전환: 분석할 공세가 부족함")
		else:
			lines.append("전략 전환: 없음 · 주력 %s" % [
				MONSTER_CATALOG.get_name(current_strategy_type)
			])
	else:
		var switch_parts: PackedStringArray = []
		for raw_switch in strategy_switches:
			var switch: Dictionary = raw_switch
			switch_parts.append("%s %s→%s" % [
				_format_time(float(switch.get("time", 0.0))),
				MONSTER_CATALOG.get_name(String(switch.get("from", ""))),
				MONSTER_CATALOG.get_name(String(switch.get("to", ""))),
			])
		lines.append("전략 전환: %s" % " / ".join(switch_parts))

	if hero_augment_events.is_empty():
		lines.append("Hero 증강 선택: 없음")
	else:
		var latest: Dictionary = hero_augment_events.back()
		lines.append("Hero 증강 %d회 · 마지막 Lv.%d %s (%s)" % [
			hero_augment_events.size(),
			int(latest.get("level", 1)),
			String(latest.get("name", "?")),
			_format_time(float(latest.get("time", 0.0))),
		])

	return "\n".join(lines)

func _update_strategy_state() -> void:
	_prune_recent_summons()

	var weights := {}
	var total_weight := 0.0
	for raw_event in recent_summons:
		var event: Dictionary = raw_event
		var monster_type := String(event.get("type", ""))
		var weight := float(event.get("weight", 0.0))
		if monster_type.is_empty() or weight <= 0.0:
			continue

		weights[monster_type] = float(weights.get(monster_type, 0.0)) + weight
		total_weight += weight

	if total_weight < STRATEGY_MIN_SPEND:
		return

	var dominant_type := ""
	var dominant_weight := 0.0
	for raw_type in weights.keys():
		var monster_type := String(raw_type)
		var weight := float(weights.get(monster_type, 0.0))
		if weight > dominant_weight:
			dominant_weight = weight
			dominant_type = monster_type

	if dominant_type.is_empty():
		return

	var dominance := dominant_weight / maxf(total_weight, 0.001)
	if dominance < STRATEGY_DOMINANCE_RATIO:
		return

	if current_strategy_type.is_empty():
		current_strategy_type = dominant_type
		last_strategy_change_time = elapsed_seconds
		return

	if dominant_type == current_strategy_type:
		return

	if elapsed_seconds - last_strategy_change_time < STRATEGY_SWITCH_COOLDOWN:
		return

	strategy_switches.append({
		"time": elapsed_seconds,
		"from": current_strategy_type,
		"to": dominant_type,
	})
	current_strategy_type = dominant_type
	last_strategy_change_time = elapsed_seconds

func _prune_recent_summons() -> void:
	var cutoff := elapsed_seconds - STRATEGY_WINDOW_SECONDS
	while not recent_summons.is_empty():
		var event: Dictionary = recent_summons[0]
		if float(event.get("time", 0.0)) >= cutoff:
			break
		recent_summons.pop_front()

static func _format_time(seconds: float) -> String:
	var total := maxi(int(round(seconds)), 0)
	var minutes := int(total / 60)
	var remaining := total % 60
	return "%02d:%02d" % [minutes, remaining]
