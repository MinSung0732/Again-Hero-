extends RefCounted
## Shared display/rating rules; the database migration stores the same thresholds.
const BADGES_PATH := "res://src/data/ranked_badges.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var file := FileAccess.open(BADGES_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary: _data = parsed
	return _data

static func tier(mmr: int, server_rank: int = 0) -> String:
	var rules := data()
	var thresholds: Array = rules.get("mmr_thresholds", [])
	var found := ""
	for entry in thresholds:
		if mmr >= int(entry.get("mmr", 0)): found = String(entry.get("id", ""))
		else: break
	if found == "demon_lord" and server_rank > 0 and server_rank <= int(rules.get("hero_qualification", {}).get("top_count", 0)):
		return "hero"
	return found

static func tier_index(mmr: int) -> int:
	var thresholds: Array = data().get("mmr_thresholds", [])
	var index := 0
	for i in thresholds.size():
		if mmr < int(thresholds[i].get("mmr", 0)): break
		index = i
	return index

static func next_tier_text(mmr: int) -> String:
	for entry in data().get("mmr_thresholds", []):
		var threshold := int(entry.get("mmr", 0))
		if threshold > mmr: return "다음 등급까지 %d점" % (threshold - mmr)
	return "상위 %d위 안이면 용사 등급" % int(data().get("hero_qualification", {}).get("top_count", 100))

static func weekly_reward_tier(demon_mmr: int, hero_mmr: int, demon_rank: int = 0, hero_rank: int = 0) -> String:
	var demon_tier := tier(demon_mmr, demon_rank)
	var hero_tier := tier(hero_mmr, hero_rank)
	# Match settlement's MMR ordering; ties select demon alphabetically.
	return demon_tier if demon_mmr >= hero_mmr else hero_tier

# Group starts come from threshold data. The initial score is the floor for bronze.
static func weekly_reset_mmr(mmr: int, server_rank: int = 0) -> int:
	var rules := data()
	var current := tier(mmr, server_rank)
	var target := String(rules.get("weekly_reset_high_tier", "")) if current in ["hero", "demon_lord"] else current.get_slice("_", 0) + "_1"
	for entry in rules.get("mmr_thresholds", []):
		if String(entry.get("id", "")) == target:
			return maxi(int(entry.get("mmr", 0)), int(rules.get("initial_mmr", 0)))
	return int(rules.get("initial_mmr", 0))

static func weekly_reward(tier_id: String) -> Dictionary:
	var rewards: Dictionary = data().get("weekly_rewards", {})
	return rewards.get(tier_id, {}).duplicate()

static func icon_path(tier_id: String) -> String:
	for asset in data().get("assets", []):
		if String(asset.get("id", "")) == tier_id: return String(asset.get("icon_path", ""))
	return ""

static func display_name(tier_id: String) -> String:
	for asset in data().get("assets", []):
		if String(asset.get("id", "")) == tier_id: return String(asset.get("display_name", tier_id))
	return tier_id

static func delta(won: bool, margin: float) -> int:
	var scoring: Dictionary = data().get("scoring", {})
	var part: Dictionary = scoring.get("win" if won else "loss", {})
	var amount := int(round(float(part.get("base", 0)) + float(part.get("margin_scale", 0)) * clampf(margin, 0.0, 1.0)))
	return amount if won else -amount

static func margins(winner: String, reason: String, elapsed: float, duration: float, hero_hp_ratio: float) -> Dictionary:
	if winner not in ["demon", "hero"]: return {}
	if reason in ["opponent_left", "reconnect_timeout"]:
		var disconnect: Dictionary = data().get("scoring", {}).get("disconnect", {})
		var winner_margin := float(disconnect.winner_margin)
		var leaver_margin := float(disconnect.leaver_margin)
		return {"demon": winner_margin if winner == "demon" else leaver_margin, "hero": winner_margin if winner == "hero" else leaver_margin}
	# One decisiveness value per match: a decisive result gives the winner more
	# (+10..30) and costs the loser more (-10..25); a close one moves both less.
	var decisive := clampf(1.0 - elapsed / maxf(duration, 0.001), 0.0, 1.0) if winner == "demon" else clampf(hero_hp_ratio, 0.0, 1.0)
	return {"demon": decisive, "hero": decisive}

static func rated_allowed(test_auth: bool, local_test_ticket: String, winner: String, reason: String, has_credentials: bool, demon_uid: String, hero_uid: String) -> bool:
	return not test_auth and local_test_ticket.is_empty() and has_credentials and winner in ["demon", "hero"] and reason not in ["practice", "preparation_cancelled", "ready_timeout", "peer_left", "both_disconnected", "battle_load_failed"] and _uid_valid(demon_uid) and _uid_valid(hero_uid) and demon_uid != hero_uid

static func _uid_valid(uid: String) -> bool:
	return uid.length() == 36 and uid[8] == "-" and uid[13] == "-" and uid[18] == "-" and uid[23] == "-" and uid.replace("-", "").is_valid_hex_number(false)

const LOCAL_PREVIEW_NOTE := "로컬 테스트 · 랭크 점수 미반영"

## Local test matches are unrated, so the lobby shows each role at the starting score.
static func local_preview_profile() -> Dictionary:
	var mmr := int(data().get("initial_mmr", 1000))
	var state := {"mmr":mmr,"tier":tier(mmr),"wins":0,"losses":0,"server_rank":0}
	return {"demon":state.duplicate(),"hero":state.duplicate(),"weekly_reward_tier":tier(mmr),"local":true}

## Compact card text: tier name + score. The hero title shows its server rank large and MMR small.
static func card_lines(state: Dictionary) -> Dictionary:
	var tier_id := String(state.get("tier", ""))
	var mmr := int(state.get("mmr", 0))
	var rank := int(state.get("server_rank", 0))
	if tier_id == "hero" and rank > 0:
		return {"name":display_name(tier_id), "score":"%d위" % rank, "small":"MMR %d" % mmr}
	return {"name":display_name(tier_id), "score":"MMR %d" % mmr, "small":""}

static func record_text(state: Dictionary) -> String:
	var wins := int(state.get("wins", 0))
	var losses := int(state.get("losses", 0))
	var total := wins + losses
	var rate := "-" if total == 0 else "%d%%" % roundi(100.0 * wins / total)
	return "%d승 %d패 · 승률 %s" % [wins, losses, rate]
