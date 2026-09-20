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
	var stacks: int = int(build_counts.get(candidate_id, 0))

	match candidate_id:
		"sword_mastery":
			if nearby_count <= 2:
				score += 1.6
			else:
				score += 0.3
			if hp_ratio >= 0.65:
				score += 0.8

		"rapid_strikes":
			score += minf(float(nearby_count) * 0.65, 3.2)
			if total_count >= 4:
				score += 0.8

		"iron_body":
			score += (1.0 - hp_ratio) * 5.0
			if hp_ratio <= 0.55:
				score += 1.2

		"pursuit":
			score += minf(nearest_distance / 220.0, 2.6)
			if total_count <= 2:
				score += 0.7

		"long_reach":
			score += minf(nearest_distance / 180.0, 3.0)
			if nearby_count == 0:
				score += 0.8

		"battle_recovery":
			score += (1.0 - hp_ratio) * 8.0
			if hp_ratio >= 0.8:
				score -= 2.5
			elif hp_ratio <= 0.45:
				score += 2.0

	# Build inertia: already invested choices are slightly more attractive.
	score += float(stacks) * 0.85

	# Keep choices from becoming fully deterministic.
	score += randf_range(-0.35, 0.35)
	return score

static func _build_reason(selected: Dictionary, context: Dictionary, build_counts: Dictionary, score: float) -> String:
	var candidate_id: String = String(selected.get("id", ""))
	var nearby_count: int = int(context.get("nearby_count", 0))
	var total_count: int = int(context.get("total_count", 0))
	var hp_ratio: float = clampf(float(context.get("hp_ratio", 1.0)), 0.0, 1.0)
	var nearest_distance: float = float(context.get("nearest_distance", 0.0))
	var stacks: int = int(build_counts.get(candidate_id, 0))
	var reason := ""

	match candidate_id:
		"sword_mastery":
			reason = "근처 적 %d명 → 안정적인 단일 화력 선호" % nearby_count
		"rapid_strikes":
			reason = "근처 적 %d명 / 전체 %d명 → 빠른 처리 능력 선호" % [nearby_count, total_count]
		"iron_body":
			reason = "현재 HP %.0f%% → 생존력 강화" % (hp_ratio * 100.0)
		"pursuit":
			reason = "가장 가까운 적 %.0f 거리 → 추격 능력 강화" % nearest_distance
		"long_reach":
			reason = "가장 가까운 적 %.0f 거리 → 공격 사거리 강화" % nearest_distance
		"battle_recovery":
			reason = "현재 HP %.0f%% → 즉시 회복 필요" % (hp_ratio * 100.0)
		_:
			reason = "현재 전황과 기본 선호도를 종합"

	if stacks > 0:
		reason += " · 기존 빌드 관성 +%d" % stacks

	reason += " · 점수 %.1f" % score
	return reason
