extends RefCounted

# Presentation only: use the already granted reward message, never recompute/pay.
static func format_message(message: String) -> Dictionary:
	var headline: PackedStringArray = []
	var rewards: PackedStringArray = []
	var details: PackedStringArray = []
	for line in message.split("\n", false):
		if line.begins_with("Run 골드 +"):
			rewards.append(line.split(" · ")[0].replace("Run 골드", "클리어 골드"))
			details.append(line)
		elif line.begins_with("Run 연구 +"):
			rewards.insert(0, line.split(" · ")[0].replace("Run 연구", "전투 연구 포인트"))
			details.append(line.replace(" · ", "\n").replace("Run 연구", "전투 연구"))
		elif line.begins_with("최초 클리어 보상"):
			rewards.append(line.replace("최초 클리어 보상 · 연구 포인트", "최초 클리어 연구"))
			details.append(line)
		elif line.begins_with("기본 +") or line.contains("보상 저장 실패"):
			details.append(line.replace(" · ", "\n"))
			if line.contains("보상 저장 실패"):
				headline.append(line.replace("Run 연구", "전투 연구"))
		else:
			headline.append(line)
	return {"headline": "\n".join(headline), "reward": "\n".join(rewards), "details": "\n".join(details)}

static func format_analysis(summary: String, reward_details: String) -> String:
	var body := "◆ 전투 분석\n" + "\n\n".join(summary.replace("Hero", "용사").replace("Run ", "전투 시간 ").split("\n", false))
	if not reward_details.is_empty():
		body += "\n\n◆ 보상 상세\n" + reward_details
	# Explicit whitespace separates each metric; long builds still wrap naturally.
	return body
