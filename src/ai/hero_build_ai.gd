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
	var stacks: int = int(build_counts.get(candidate_id, 0))

	var slime_ratio: float = _ratio(int(type_counts.get("slime", 0)), total_count)
	var spider_ratio: float = _ratio(int(type_counts.get("spider", 0)), total_count)
	var orc_ratio: float = _ratio(int(type_counts.get("orc", 0)), total_count)
	var swarm_ratio: float = _ratio(int(role_counts.get("swarm", 0)), total_count)
	var controller_ratio: float = _ratio(int(role_counts.get("controller", 0)), total_count)
	var tank_ratio: float = _ratio(int(role_counts.get("tank", 0)), total_count)

	match candidate_id:
		"projectile_power":
			score += orc_ratio * 4.0
			score += tank_ratio * 2.0
			if nearby_count <= 2:
				score += 1.0
			if hp_ratio >= 0.65:
				score += 0.6

		"rapid_strikes":
			score += minf(float(nearby_count) * 0.55, 2.8)
			score += slime_ratio * 3.5
			score += swarm_ratio * 2.0
			if total_count >= 4:
				score += 0.6

		"iron_body":
			score += (1.0 - hp_ratio) * 5.0
			score += orc_ratio * 2.5
			score += tank_ratio * 1.5
			if hp_ratio <= 0.55:
				score += 1.0

		"pursuit":
			score += minf(nearest_distance / 220.0, 2.3)
			score += spider_ratio * 3.5
			score += controller_ratio * 2.0
			if total_count <= 2:
				score += 0.5

		"long_reach":
			score += minf(nearest_distance / 180.0, 2.7)
			score += spider_ratio * 1.8
			if nearby_count == 0:
				score += 0.7

		"battle_recovery":
			score += (1.0 - hp_ratio) * 8.0
			score += tank_ratio * 0.8
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
	var stacks: int = int(build_counts.get(candidate_id, 0))

	var slime_ratio: float = _ratio(int(type_counts.get("slime", 0)), total_count)
	var spider_ratio: float = _ratio(int(type_counts.get("spider", 0)), total_count)
	var orc_ratio: float = _ratio(int(type_counts.get("orc", 0)), total_count)
	var reason := ""

	match candidate_id:
		"projectile_power":
			if orc_ratio >= 0.30:
				reason = "오크 비중 %.0f%% → 투사체 화력 강화" % (orc_ratio * 100.0)
			else:
				reason = "근처 적 %d명 → 안정적인 투사체 화력 선호" % nearby_count
		"rapid_strikes":
			if slime_ratio >= 0.40:
				reason = "슬라임 비중 %.0f%% → 빠른 물량 처리 선호" % (slime_ratio * 100.0)
			else:
				reason = "근처 적 %d명 / 전체 %d명 → 처리 속도 강화" % [nearby_count, total_count]
		"iron_body":
			if orc_ratio >= 0.30:
				reason = "오크 압박 %.0f%% + HP %.0f%% → 생존력 강화" % [orc_ratio * 100.0, hp_ratio * 100.0]
			else:
				reason = "현재 HP %.0f%% → 생존력 강화" % (hp_ratio * 100.0)
		"pursuit":
			if spider_ratio >= 0.30:
				reason = "거미 비중 %.0f%% → 둔화 대응 기동력 보강" % (spider_ratio * 100.0)
			else:
				reason = "가장 가까운 적 %.0f 거리 → 추격 능력 강화" % nearest_distance
		"long_reach":
			if spider_ratio >= 0.30:
				reason = "거미 비중 %.0f%% → 접근 전 공격 선호" % (spider_ratio * 100.0)
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
