extends SceneTree

const MODES := preload("res://src/ui/lobby_main_modes_view.gd")
const PROFILE_VIEW := preload("res://src/ui/lobby_profile_view.gd")

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
	modes.ranked_profile_card.add_child(modes.ranked_profile_icon)
	modes.ranked_profile_card.add_child(modes.ranked_profile_label)
	var payload := {"demon":{"mmr":1099,"tier":"bronze_1","wins":4,"losses":2,"server_rank":20}, "hero":{"mmr":2900,"tier":"diamond_4","wins":9,"losses":1,"server_rank":5}, "weekly_reward_tier":"diamond_4"}
	modes._on_ranked_profile("ranked_profile", 200, payload)
	assert(modes.ranked_profile_icon.texture != null and modes.ranked_profile_label.text.contains("MMR 1099") and modes.ranked_profile_label.text.contains("1점"))
	modes.perspective = "hero"
	modes._show_ranked_profile()
	assert(modes.ranked_profile_label.text.contains("MMR 2900") and modes.ranked_profile_label.text.contains("400점"))
	var profile := PROFILE_VIEW.new()
	profile.lobby = host
	var column := VBoxContainer.new()
	host.add_child(column)
	profile._build_rank_section(column)
	profile._refresh_rank()
	assert(profile.rank_icons.hero.texture != null and profile.rank_icons.demon.texture != null)
	assert(profile.rank_labels.hero.text.contains("MMR 2900") and profile.rank_labels.demon.text.contains("MMR 1099"))
	assert(profile.rank_weekly.text.contains("주간 보상 기준") and profile.rank_weekly.text.contains("다이아"))
	modes._on_ranked_profile("ranked_profile", 500, {})
	assert(modes.ranked_profile_label.text == MODES.RANK_ERROR)
	profile._refresh_rank()
	assert(profile.rank_labels.hero.text == PROFILE_VIEW.RANK_ERROR)
	host.queue_free()
	print("RANKED_PROFILE_DISPLAY_SMOKE PASS")
	quit()
