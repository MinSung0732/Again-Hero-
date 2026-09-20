extends RefCounted
class_name HeroBuildAI

static func choose_candidate_v0(candidates: Array) -> Dictionary:
	var selected: Dictionary = {}
	var selected_score: float = -INF

	for candidate in candidates:
		var base_score: float = float(candidate.get("base_score", 0.0))
		var score: float = base_score + randf_range(-0.75, 0.75)
		if score > selected_score:
			selected_score = score
			selected = candidate.duplicate(true)

	selected["decision_score"] = selected_score
	selected["decision_reason"] = "기본 선호도 + 작은 랜덤값"
	return selected
