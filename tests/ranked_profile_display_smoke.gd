extends SceneTree

const MODES := preload("res://src/ui/lobby_main_modes_view.gd")
const PROFILE_VIEW := preload("res://src/ui/lobby_profile_view.gd")
const RANKED := preload("res://src/data/ranked_rules.gd")

class Host extends Control:
	var main_modes_view

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var host := Host.new()
	root.add_child(host)
	var modes := MODES.new()
	host.main_modes_view = modes
	modes.lobby = host
	modes.ranked = true
	modes.ranked_profile_owner = root.get_node("LoginGateway").user_id
	modes.ranked_profile_card = PanelContainer.new()
	host.add_child(modes.ranked_profile_card)
	modes.ranked_profile_icon = TextureRect.new()
	modes.ranked_profile_label = Label.new()
	modes.ranked_profile_row = HBoxContainer.new()
	modes.ranked_profile_card.add_child(modes.ranked_profile_row)
	modes.ranked_profile_card.add_child(modes.ranked_profile_icon)
	modes.ranked_profile_card.add_child(modes.ranked_profile_label)
	modes.ranked_profile_score = Label.new()
	modes.ranked_profile_small = Label.new()
	modes.ranked_profile_card.add_child(modes.ranked_profile_score)
	modes.ranked_profile_card.add_child(modes.ranked_profile_small)
	var payload := {"demon":{"mmr":1099,"tier":"bronze_1","wins":4,"losses":2,"server_rank":20}, "hero":{"mmr":2900,"tier":"diamond_4","wins":9,"losses":1,"server_rank":5}, "weekly_reward_tier":"diamond_4"}
	modes._on_ranked_profile("ranked_profile", 200, payload)
	assert(modes.ranked_profile_icon.texture != null and modes.ranked_profile_label.text == RANKED.display_name("bronze_1") and modes.ranked_profile_score.text == "MMR 1099" and not modes.ranked_profile_small.visible)
	modes.perspective = "hero"
	modes._show_ranked_profile()
	assert(modes.ranked_profile_score.text == "MMR 2900")
	var hero_title := {"mmr":3400,"tier":"hero","wins":30,"losses":10,"server_rank":12}
	var lines: Dictionary = RANKED.card_lines(hero_title)
	assert(lines.score == "12위" and lines.small == "MMR 3400")
	assert(RANKED.record_text(hero_title) == "30승 10패 · 승률 75%" and RANKED.record_text({}) == "0승 0패 · 승률 -")
	var profile := PROFILE_VIEW.new()
	profile.lobby = host
	var column := VBoxContainer.new()
	host.add_child(column)
	profile._build_rank_section(column)
	profile._refresh_rank()
	assert(profile.rank_icons.hero.texture != null and profile.rank_icons.demon.texture != null)
	assert(profile.rank_labels.hero.text.contains("MMR 2900") and profile.rank_labels.demon.text.contains("MMR 1099"))
	assert(profile.rank_smalls.hero.text.contains("9승 1패 · 승률 90%") and profile.rank_smalls.demon.text.contains("서버 20위"))
	assert(profile.rank_weekly.text.contains("주간 보상 기준") and profile.rank_weekly.text.contains("다이아"))
	modes._on_ranked_profile("ranked_profile", 500, {})
	assert(modes.ranked_profile_label.text == MODES.RANK_ERROR and not modes.ranked_profile_score.visible)
	profile._refresh_rank()
	assert(profile.rank_labels.hero.text == PROFILE_VIEW.RANK_ERROR)
	var local_mode := root.get_node("LocalTestMode")
	var was_active: bool = local_mode.active
	local_mode.active = true
	modes._request_ranked_profile()
	local_mode.active = was_active
	assert(modes.ranked_profile_score.text == "MMR 1000" and modes.ranked_profile_small.text.contains(RANKED.LOCAL_PREVIEW_NOTE))
	profile._refresh_rank()
	assert(profile.rank_labels.demon.text.contains("MMR 1000") and profile.rank_weekly.text.contains(RANKED.LOCAL_PREVIEW_NOTE))
	host.queue_free()
	print("RANKED_PROFILE_DISPLAY_SMOKE PASS")
	quit()
