extends RefCounted
class_name HeroBuildAI

static func choose_candidate(candidates: Array, context: Dictionary, build_counts: Dictionary) -> Dictionary:
	var selected: Dictionary = {}
	var selected_score: float = -INF
	var score_debug: Dictionary = {}

	for candidate in candidates:
		var candidate_id: String = String(candidate.get("id", ""))
		var score: float = _score_candidate(candidate, context, build_counts)
		score_debug[candidate_id] = score

		if score > selected_score:
			selected_score = score
			selected = candidate.duplicate(true)

	selected["decision_score"] = selected_score
	selected["decision_reason"] = _build_reason(selected, context, build_counts, selected_score)
	selected["candidate_scores"] = score_debug
	return selected

static func _score_candidate(candidate: Dictionary, context: Dictionary, build_counts: Dictionary) -> float:
	var candidate_id: String = String(candidate.get("id", ""))
	var score: float = float(candidate.get("base_score", 0.0))

	var nearby_count: int = int(context.get("nearby_count", 0))
	var total_count: int = int(context.get("total_count", 0))
	var hp_ratio: float = clampf(float(context.get("hp_ratio", 1.0)), 0.0, 1.0)
	var nearest_distance: float = float(context.get("nearest_distance", 9999.0))
	var type_counts: Dictionary = context.get("type_counts", {})
	var role_counts: Dictionary = context.get("role_counts", {})
	var recent_event_count: int = int(context.get("recent_event_count", 0))
	var recent_total_weight: float = float(context.get("recent_total_weight", 0.0))
	var recent_type_weights: Dictionary = context.get("recent_type_weights", {})
	var recent_role_weights: Dictionary = context.get("recent_role_weights", {})
	var stacks: int = int(build_counts.get(candidate_id, 0))

	var slime_ratio: float = _ratio(int(type_counts.get("slime", 0)), total_count)
	var spider_ratio: float = _ratio(int(type_counts.get("spider", 0)), total_count)
	var orc_ratio: float = _ratio(int(type_counts.get("orc", 0)), total_count)
	var swarm_ratio: float = _ratio(int(role_counts.get("swarm", 0)), total_count)
	var controller_ratio: float = _ratio(int(role_counts.get("controller", 0)), total_count)
	var tank_ratio: float = _ratio(int(role_counts.get("tank", 0)), total_count)

	var recent_slime_ratio := _weighted_ratio(
		float(recent_type_weights.get("slime", 0.0)),
		recent_total_weight
	)
	var recent_spider_ratio := _weighted_ratio(
		float(recent_type_weights.get("spider", 0.0)),
		recent_total_weight
	)
	var recent_orc_ratio := _weighted_ratio(
		float(recent_type_weights.get("orc", 0.0)),
		recent_total_weight
	)
	var recent_swarm_ratio := _weighted_ratio(
		float(recent_role_weights.get("swarm", 0.0)),
		recent_total_weight
	)
	var recent_controller_ratio := _weighted_ratio(
		float(recent_role_weights.get("controller", 0.0)),
		recent_total_weight
	)
	var recent_tank_ratio := _weighted_ratio(
		float(recent_role_weights.get("tank", 0.0)),
		recent_total_weight
	)

	match candidate_id:
		"projectile_power":
			score += orc_ratio * 4.0
			score += tank_ratio * 2.0
			score += recent_orc_ratio * 2.6
			score += recent_tank_ratio * 1.4
			if nearby_count <= 2:
				score += 1.0
			if hp_ratio >= 0.65:
				score += 0.6

		"rapid_strikes":
			score += minf(float(nearby_count) * 0.55, 2.8)
			score += slime_ratio * 3.5
			score += swarm_ratio * 2.0
			score += recent_slime_ratio * 3.2
			score += recent_swarm_ratio * 1.8
			score += minf(float(recent_event_count) * 0.10, 0.8)
			if total_count >= 4:
				score += 0.6

		"iron_body":
			score += (1.0 - hp_ratio) * 5.0
			score += orc_ratio * 2.5
			score += tank_ratio * 1.5
			score += recent_orc_ratio * 1.5
			score += recent_tank_ratio * 0.8
			if hp_ratio <= 0.55:
				score += 1.0

		"pursuit":
			score += minf(nearest_distance / 220.0, 2.3)
			score += spider_ratio * 3.5
			score += controller_ratio * 2.0
			score += recent_spider_ratio * 3.0
			score += recent_controller_ratio * 1.6
			if total_count <= 2:
				score += 0.5

		"long_reach":
			score += minf(nearest_distance / 180.0, 2.7)
			score += spider_ratio * 1.8
			score += recent_spider_ratio * 1.4
			score += recent_controller_ratio * 0.8
			if nearby_count == 0:
				score += 0.7

		"battle_recovery":
			score += (1.0 - hp_ratio) * 8.0
			score += tank_ratio * 0.8
			score += recent_tank_ratio * 0.5
			if hp_ratio >= 0.8:
				score -= 2.5
			elif hp_ratio <= 0.45:
				score += 2.0

	score += float(stacks) * 0.85
	score += randf_range(-0.35, 0.35)
	return score

static func _build_reason(selected: Dictionary, context: Dictionary, build_counts: Dictionary, score: float) -> String:
	var candidate_id: String = String(selected.get("id", ""))
	var nearby_count: int = int(context.get("nearby_count", 0))
	var total_count: int = int(context.get("total_count", 0))
	var hp_ratio: float = clampf(float(context.get("hp_ratio", 1.0)), 0.0, 1.0)
	var nearest_distance: float = float(context.get("nearest_distance", 0.0))
	var type_counts: Dictionary = context.get("type_counts", {})
	var recent_event_count: int = int(context.get("recent_event_count", 0))
	var recent_total_weight: float = float(context.get("recent_total_weight", 0.0))
	var recent_type_weights: Dictionary = context.get("recent_type_weights", {})
	var recent_window_seconds: float = float(context.get("recent_window_seconds", 20.0))
	var stacks: int = int(build_counts.get(candidate_id, 0))

	var slime_ratio: float = _ratio(int(type_counts.get("slime", 0)), total_count)
	var spider_ratio: float = _ratio(int(type_counts.get("spider", 0)), total_count)
	var orc_ratio: float = _ratio(int(type_counts.get("orc", 0)), total_count)
	var recent_slime_ratio := _weighted_ratio(
		float(recent_type_weights.get("slime", 0.0)),
		recent_total_weight
	)
	var recent_spider_ratio := _weighted_ratio(
		float(recent_type_weights.get("spider", 0.0)),
		recent_total_weight
	)
	var recent_orc_ratio := _weighted_ratio(
		float(recent_type_weights.get("orc", 0.0)),
		recent_total_weight
	)
	var reason := ""

	match candidate_id:
		"projectile_power":
			if recent_event_count >= 2 and recent_orc_ratio >= 0.35:
				reason = "최근 %.0f초 오크 공세 %.0f%% → 단일 화력 강화" % [
					recent_window_seconds,
					recent_orc_ratio * 100.0,
				]
			elif orc_ratio >= 0.30:
				reason = "현재 오크 비중 %.0f%% → 투사체 화력 강화" % (orc_ratio * 100.0)
			else:
				reason = "근처 적 %d명 → 안정적인 투사체 화력 선호" % nearby_count
		"rapid_strikes":
			if recent_event_count >= 3 and recent_slime_ratio >= 0.40:
				reason = "최근 %.0f초 슬라임 공세 %.0f%% → 물량 처리 속도 강화" % [
					recent_window_seconds,
					recent_slime_ratio * 100.0,
				]
			elif slime_ratio >= 0.40:
				reason = "현재 슬라임 비중 %.0f%% → 빠른 물량 처리 선호" % (slime_ratio * 100.0)
			else:
				reason = "근처 적 %d명 / 전체 %d명 → 처리 속도 강화" % [nearby_count, total_count]
		"iron_body":
			if recent_event_count >= 2 and recent_orc_ratio >= 0.40:
				reason = "최근 오크 압박 %.0f%% + HP %.0f%% → 생존력 강화" % [
					recent_orc_ratio * 100.0,
					hp_ratio * 100.0,
				]
			elif orc_ratio >= 0.30:
				reason = "현재 오크 압박 %.0f%% + HP %.0f%% → 생존력 강화" % [orc_ratio * 100.0, hp_ratio * 100.0]
			else:
				reason = "현재 HP %.0f%% → 생존력 강화" % (hp_ratio * 100.0)
		"pursuit":
			if recent_event_count >= 2 and recent_spider_ratio >= 0.35:
				reason = "최근 %.0f초 거미 공세 %.0f%% → 둔화 대응 기동력 보강" % [
					recent_window_seconds,
					recent_spider_ratio * 100.0,
				]
			elif spider_ratio >= 0.30:
				reason = "현재 거미 비중 %.0f%% → 둔화 대응 기동력 보강" % (spider_ratio * 100.0)
			else:
				reason = "가장 가까운 적 %.0f 거리 → 추격 능력 강화" % nearest_distance
		"long_reach":
			if recent_event_count >= 2 and recent_spider_ratio >= 0.40:
				reason = "최근 거미 공세 %.0f%% → 접근 전 공격 거리 확보" % (recent_spider_ratio * 100.0)
			elif spider_ratio >= 0.30:
				reason = "현재 거미 비중 %.0f%% → 접근 전 공격 선호" % (spider_ratio * 100.0)
			else:
				reason = "가장 가까운 적 %.0f 거리 → 공격 사거리 강화" % nearest_distance
		"battle_recovery":
			reason = "현재 HP %.0f%% → 즉시 회복 필요" % (hp_ratio * 100.0)
		_:
			reason = "현재 전황과 몬스터 구성을 종합"

	if stacks > 0:
		reason += " · 기존 빌드 관성 +%d" % stacks

	reason += " · 점수 %.1f" % score
	return reason

static func _ratio(count: int, total: int) -> float:
	if total <= 0:
		return 0.0
	return float(count) / float(total)


static func _weighted_ratio(weight: float, total_weight: float) -> float:
	if total_weight <= 0.0001:
		return 0.0
	return weight / total_weight
