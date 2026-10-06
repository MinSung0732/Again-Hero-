extends RefCounted

static func blocked_reason(monster_ids: Array, skill_ids: Array, exempt: bool) -> String:
	if exempt:
		return ""
	if monster_ids.size() != 3 and skill_ids.size() != 3:
		return "팀 편성에서 몬스터 3마리와 마왕 스킬 3개를 편성해 주세요."
	if monster_ids.size() != 3:
		return "팀 편성에서 몬스터 3마리를 편성해 주세요."
	if skill_ids.size() != 3:
		return "팀 편성에서 마왕 스킬 3개를 편성해 주세요."
	return ""
