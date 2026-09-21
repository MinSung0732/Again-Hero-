extends RefCounted
class_name HeroBuildAI

const MONSTER_CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENT_CATALOG := preload("res://src/data/hero_augment_catalog.gd")
const STATUS_EFFECT_CATALOG := preload("res://src/data/status_effect_catalog.gd")

static func choose_candidate(
	candidates: Array,
	context: Dictionary,
	build_counts: Dictionary,
	ai_settings: Dictionary
) -> Dictionary:
	if candidates.is_empty():
		return {}

	var selected: Dictionary = {}
	var selected_score := -INF
	var selected_synergy_score := 0.0
	var score_debug := {}
	var synergy_debug := {}
	var build_tag_counts := AUGMENT_CATALOG.get_build_tag_counts(build_counts)

	for raw_candidate in candidates:
		var candidate: Dictionary = raw_candidate
		var candidate_id := String(candidate.get("id", ""))
		var synergy_score := _score_synergy(
			candidate,
			build_counts,
			build_tag_counts
		)
		var score := _score_candidate(
			candidate,
			context,
			build_counts,
			ai_settings,
			synergy_score
		)

		score_debug[candidate_id] = score
		synergy_debug[candidate_id] = synergy_score

		if score > selected_score:
			selected_score = score
			selected_synergy_score = synergy_score
			selected = candidate.duplicate(true)

	selected["decision_score"] = selected_score
	selected["synergy_score"] = selected_synergy_score
	selected["decision_reason"] = _build_reason(
		selected,
		context,
		build_counts,
		selected_score,
		ai_settings,
		build_tag_counts,
		selected_synergy_score
	)
	selected["candidate_scores"] = score_debug
	selected["candidate_synergy_scores"] = synergy_debug
	return selected

static func _score_candidate(
	candidate: Dictionary,
	context: Dictionary,
	build_counts: Dictionary,
	ai_settings: Dictionary,
	synergy_score: float
) -> float:
	var candidate_id := String(candidate.get("id", ""))
	var score := float(candidate.get("base_score", 0.0))
	var augment_biases: Dictionary = ai_settings.get("augment_biases", {})
	score += float(augment_biases.get(candidate_id, 0.0))

	for raw_rule in candidate.get("ai_rules", []):
		var rule: Dictionary = raw_rule
		score += _evaluate_rule(rule, context)

	score += synergy_score

	var stacks := int(build_counts.get(candidate_id, 0))
	var stack_inertia := float(
		candidate.get(
			"stack_inertia",
			ai_settings.get("stack_inertia", 0.85)
		)
	)
	score += float(stacks) * stack_inertia

	if not build_counts.is_empty() and stacks <= 0:
		score -= maxf(float(ai_settings.get("new_branch_penalty", 0.0)), 0.0)

	var randomness := float(candidate.get("randomness", 0.35))
	score += randf_range(-randomness, randomness)
	return score

static func _score_synergy(
	candidate: Dictionary,
	build_counts: Dictionary,
	build_tag_counts: Dictionary
) -> float:
	var total := 0.0

	for raw_rule in candidate.get("synergy_rules", []):
		var rule: Dictionary = raw_rule
		total += _evaluate_synergy_rule(
			rule,
			build_counts,
			build_tag_counts
		)

	return total

static func _evaluate_synergy_rule(
	rule: Dictionary,
	build_counts: Dictionary,
	build_tag_counts: Dictionary
) -> float:
	var source := String(rule.get("source", ""))
	var key := String(rule.get("key", ""))

	match source:
		"build_tag_stacks":
			var stacks := int(build_tag_counts.get(key, 0))
			var contribution := float(stacks) * float(rule.get("weight", 0.0))
			return _apply_optional_cap(contribution, rule)
		"build_tag_present":
			if int(build_tag_counts.get(key, 0)) > 0:
				return float(rule.get("bonus", 0.0))
		"build_augment_stacks":
			var stacks := int(build_counts.get(key, 0))
			var contribution := float(stacks) * float(rule.get("weight", 0.0))
			return _apply_optional_cap(contribution, rule)
		"build_augment_present":
			if int(build_counts.get(key, 0)) > 0:
				return float(rule.get("bonus", 0.0))

	return 0.0

static func _apply_optional_cap(value: float, rule: Dictionary) -> float:
	if not rule.has("cap"):
		return value

	var cap_value := absf(float(rule.get("cap", 0.0)))
	if value >= 0.0:
		return minf(value, cap_value)
	return maxf(value, -cap_value)

static func _evaluate_rule(rule: Dictionary, context: Dictionary) -> float:
	var source := String(rule.get("source", ""))

	match source:
		"current_type_ratio":
			return _current_ratio(
				context,
				"type_counts",
				String(rule.get("key", ""))
			) * float(rule.get("weight", 0.0))
		"current_role_ratio":
			return _current_ratio(
				context,
				"role_counts",
				String(rule.get("key", ""))
			) * float(rule.get("weight", 0.0))
		"recent_type_ratio":
			return _recent_ratio(
				context,
				"recent_type_weights",
				String(rule.get("key", ""))
			) * float(rule.get("weight", 0.0))
		"recent_role_ratio":
			return _recent_ratio(
				context,
				"recent_role_weights",
				String(rule.get("key", ""))
			) * float(rule.get("weight", 0.0))
		"recent_status_weight":
			var status_weights: Dictionary = context.get("recent_status_weights", {})
			var status_id := String(rule.get("key", ""))
			var contribution := (
				float(status_weights.get(status_id, 0.0))
				* float(rule.get("weight", 0.0))
			)
			return _apply_optional_cap(contribution, rule)
		"nearby_linear":
			return minf(
				float(context.get("nearby_count", 0))
				* float(rule.get("weight", 0.0)),
				float(rule.get("cap", INF))
			)
		"recent_events_linear":
			return minf(
				float(context.get("recent_event_count", 0))
				* float(rule.get("weight", 0.0)),
				float(rule.get("cap", INF))
			)
		"hp_missing":
			var hp_ratio := clampf(
				float(context.get("hp_ratio", 1.0)),
				0.0,
				1.0
			)
			return (1.0 - hp_ratio) * float(rule.get("weight", 0.0))
		"distance":
			var divisor := maxf(float(rule.get("divisor", 1.0)), 0.001)
			return minf(
				float(context.get("nearest_distance", 0.0)) / divisor,
				float(rule.get("cap", INF))
			)
		"nearby_count_max":
			return (
				float(rule.get("bonus", 0.0))
				if int(context.get("nearby_count", 0))
				<= int(rule.get("value", 0))
				else 0.0
			)
		"nearby_count_eq":
			return (
				float(rule.get("bonus", 0.0))
				if int(context.get("nearby_count", 0))
				== int(rule.get("value", 0))
				else 0.0
			)
		"total_count_min":
			return (
				float(rule.get("bonus", 0.0))
				if int(context.get("total_count", 0))
				>= int(rule.get("value", 0))
				else 0.0
			)
		"total_count_max":
			return (
				float(rule.get("bonus", 0.0))
				if int(context.get("total_count", 0))
				<= int(rule.get("value", 0))
				else 0.0
			)
		"hp_ratio_min":
			return (
				float(rule.get("bonus", 0.0))
				if float(context.get("hp_ratio", 1.0))
				>= float(rule.get("value", 0.0))
				else 0.0
			)
		"hp_ratio_max":
			return (
				float(rule.get("bonus", 0.0))
				if float(context.get("hp_ratio", 1.0))
				<= float(rule.get("value", 1.0))
				else 0.0
			)

	return 0.0

static func _build_reason(
	selected: Dictionary,
	context: Dictionary,
	build_counts: Dictionary,
	score: float,
	ai_settings: Dictionary,
	build_tag_counts: Dictionary,
	synergy_score: float
) -> String:
	var best_rule: Dictionary = {}
	var best_contribution := 0.0

	for raw_rule in selected.get("ai_rules", []):
		var rule: Dictionary = raw_rule
		var contribution := _evaluate_rule(rule, context)
		if contribution > best_contribution:
			best_contribution = contribution
			best_rule = rule

	var reason := _describe_rule(best_rule, context)
	if reason.is_empty():
		reason = "관측 전황과 최근 공세 기록을 종합"

	if synergy_score > 0.01:
		var synergy_reason := _describe_best_synergy(
			selected,
			build_counts,
			build_tag_counts
		)
		if not synergy_reason.is_empty():
			reason += " · %s" % synergy_reason

	var candidate_name := String(selected.get("name", "증강"))
	reason += " → %s 선호" % candidate_name

	var augment_biases: Dictionary = ai_settings.get("augment_biases", {})
	var personality_bias := float(
		augment_biases.get(String(selected.get("id", "")), 0.0)
	)
	if absf(personality_bias) >= 0.05:
		reason += " · 성향 보정 %.1f" % personality_bias

	var observation_age := maxf(
		float(context.get("observation_age", 0.0)),
		0.0
	)
	if observation_age >= 0.25:
		reason += " · %.1f초 전 관측" % observation_age

	var candidate_id := String(selected.get("id", ""))
	var stacks := int(build_counts.get(candidate_id, 0))
	if stacks > 0:
		reason += " · 기존 빌드 관성 +%d" % stacks
	elif (
		not build_counts.is_empty()
		and float(ai_settings.get("new_branch_penalty", 0.0)) > 0.0
	):
		reason += " · 새 갈래 전환 저항"

	reason += " · 점수 %.1f" % score
	return reason

static func _describe_best_synergy(
	candidate: Dictionary,
	build_counts: Dictionary,
	build_tag_counts: Dictionary
) -> String:
	var best_rule: Dictionary = {}
	var best_contribution := 0.0

	for raw_rule in candidate.get("synergy_rules", []):
		var rule: Dictionary = raw_rule
		var contribution := _evaluate_synergy_rule(
			rule,
			build_counts,
			build_tag_counts
		)
		if contribution > best_contribution:
			best_contribution = contribution
			best_rule = rule

	if best_rule.is_empty() or best_contribution <= 0.0:
		return ""

	var source := String(best_rule.get("source", ""))
	var key := String(best_rule.get("key", ""))

	match source:
		"build_tag_stacks", "build_tag_present":
			var stacks := int(build_tag_counts.get(key, 0))
			return "기존 %s %d스택 시너지 +%.1f" % [
				AUGMENT_CATALOG.get_tag_label(key),
				stacks,
				best_contribution,
			]
		"build_augment_stacks", "build_augment_present":
			var augment := AUGMENT_CATALOG.get_augment(key)
			var augment_name := String(augment.get("name", key))
			var stacks := int(build_counts.get(key, 0))
			return "기존 %s %d스택 시너지 +%.1f" % [
				augment_name,
				stacks,
				best_contribution,
			]

	return ""

static func _describe_rule(rule: Dictionary, context: Dictionary) -> String:
	if rule.is_empty():
		return ""

	var source := String(rule.get("source", ""))
	var key := String(rule.get("key", ""))
	var window := float(context.get("recent_window_seconds", 20.0))

	match source:
		"current_type_ratio":
			return "관측 전장 %s 비중 %.0f%%" % [
				MONSTER_CATALOG.get_name(key),
				_current_ratio(context, "type_counts", key) * 100.0,
			]
		"current_role_ratio":
			return "관측 전장 %s 비중 %.0f%%" % [
				MONSTER_CATALOG.get_role_label(key),
				_current_ratio(context, "role_counts", key) * 100.0,
			]
		"recent_type_ratio":
			return "최근 %.0f초 %s 공세 %.0f%%" % [
				window,
				MONSTER_CATALOG.get_name(key),
				_recent_ratio(
					context,
					"recent_type_weights",
					key
				) * 100.0,
			]
		"recent_role_ratio":
			return "최근 %.0f초 %s 공세 %.0f%%" % [
				window,
				MONSTER_CATALOG.get_role_label(key),
				_recent_ratio(
					context,
					"recent_role_weights",
					key
				) * 100.0,
			]
		"recent_status_weight":
			var status_counts: Dictionary = context.get("recent_status_counts", {})
			var status_window := float(
				context.get("recent_status_window_seconds", window)
			)
			return "최근 %.0f초 %s %d회" % [
				status_window,
				STATUS_EFFECT_CATALOG.get_name(key),
				int(status_counts.get(key, 0)),
			]
		"nearby_linear", "nearby_count_max", "nearby_count_eq":
			return "관측 근처 적 %d명" % int(
				context.get("nearby_count", 0)
			)
		"recent_events_linear":
			return "최근 %.0f초 플레이어 소환 %d회" % [
				window,
				int(context.get("recent_event_count", 0)),
			]
		"hp_missing", "hp_ratio_min", "hp_ratio_max":
			return "관측 HP %.0f%%" % (
				clampf(
					float(context.get("hp_ratio", 1.0)),
					0.0,
					1.0
				) * 100.0
			)
		"distance":
			return "관측 최근접 적 %.0f 거리" % float(
				context.get("nearest_distance", 0.0)
			)
		"total_count_min", "total_count_max":
			return "관측 전체 적 %d명" % int(
				context.get("total_count", 0)
			)

	return ""

static func _current_ratio(
	context: Dictionary,
	count_key: String,
	item_key: String
) -> float:
	var total := int(context.get("total_count", 0))
	if total <= 0:
		return 0.0

	var counts: Dictionary = context.get(count_key, {})
	return float(counts.get(item_key, 0)) / float(total)

static func _recent_ratio(
	context: Dictionary,
	weight_key: String,
	item_key: String
) -> float:
	var total_weight := float(context.get("recent_total_weight", 0.0))
	if total_weight <= 0.0001:
		return 0.0

	var weights: Dictionary = context.get(weight_key, {})
	return float(weights.get(item_key, 0.0)) / total_weight
