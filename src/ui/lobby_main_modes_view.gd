extends RefCounted

# Preview state is session-local: it must not unlock stages or save fake rankings.
const PROFILE := preload("res://src/systems/player_profile.gd")
const UNLOCKS := preload("res://src/systems/mode_unlock_store.gd")
const UNLOCK_DATA := preload("res://src/data/mode_unlock_catalog.gd")
const UNLOCK_FEEDBACK := preload("res://src/ui/mode_unlock_feedback.gd")
const ART := "res://assets/art/UI/main_modes/"
var idle_style: StyleBoxTexture
var active_style: StyleBoxTexture
var icons: Dictionary = {}
var lobby
var ranked := false
var perspective := "demon"
var difficulty := "easy"
var hero_index := 0
var heroes: Array[Dictionary] = []
var difficulty_row: HBoxContainer
var mode_row: HBoxContainer
var demon_button: Button
var hero_button: Button
var ranked_button: Button
var easy_button: Button
var hard_button: Button
var character_button: Button
var notice: AcceptDialog
var unlock_feedback: CanvasLayer
var _unlock_scheduled := false
var _announced_this_session: Dictionary = {}

func install(host) -> void:
	lobby = host
	idle_style = lobby._make_svg_style(ART + "selector_idle.svg", 22, 22, 18, 10)
	active_style = lobby._make_svg_style(ART + "selector_active.svg", 22, 22, 18, 10)
	for id in ["demon", "hero", "rank", "easy", "hard", "lock"]:
		icons[id] = lobby._load_svg_texture_direct(ART + "icon_" + id + ".svg")
	var top: Control = lobby.hero_name_label.get_parent()
	var bottom: Control = lobby.stage_description_label.get_parent()
	difficulty_row = HBoxContainer.new()
	difficulty_row.name = "DifficultySelector"
	top.add_child(difficulty_row)
	place(difficulty_row, 0.18, 0.0, 0.82, 0.065)
	difficulty_row.add_theme_constant_override("separation", 10)
	easy_button = button(difficulty_row, "쉬움", func(): choose_difficulty("easy"))
	hard_button = button(difficulty_row, "어려움", func(): choose_difficulty("hard"))
	mode_row = HBoxContainer.new()
	mode_row.name = "MainModeSelector"
	mode_row.add_theme_constant_override("separation", 12)
	bottom.add_child(mode_row)
	place(mode_row, 0.03, 0.81, 0.97, 1.02)
	var sides := HBoxContainer.new()
	sides.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sides.add_theme_constant_override("separation", 6)
	mode_row.add_child(sides)
	demon_button = button(sides, "마왕", func(): choose_perspective("demon"))
	hero_button = button(sides, "용사", func(): choose_perspective("hero"))
	ranked_button = button(mode_row, "랭킹 매칭", toggle_ranked)
	character_button = Button.new()
	character_button.name = "CharacterSelector"
	character_button.text = "캐릭터 선택  ›"
	character_button.z_index = 4
	top.add_child(character_button)
	place(character_button, 0.52, 0.45, 0.86, 0.51)
	style_button(character_button, false, "hero", 22)
	character_button.pressed.connect(open_characters)
	notice = AcceptDialog.new()
	notice.title = "준비 중"
	skin_dialog(notice)
	lobby.add_child(notice)
	for id in lobby.stage_ids:
		var stage: Dictionary = lobby.STAGE_CATALOG.get_stage(id)
		if lobby.STAGE_PROGRESS.is_stage_unlocked(int(stage.get("number", 999))):
			heroes.append(stage)
	for label in [lobby.stage_description_label, lobby.stage_status_label, lobby.stage_reward_label, bottom.get_node("RepeatReward")]:
		label.add_theme_font_size_override("font_size", 21 if label == lobby.stage_description_label else 20)
	# A single framed tray visually groups the two perspectives and ranked toggle.
	var tray := Panel.new()
	tray.name = "ModeSelectorTray"
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(tray)
	bottom.move_child(tray, 0)
	place(tray, 0.01, 0.78, 0.99, 1.05)
	tray.add_theme_stylebox_override("panel", idle_style)
	var transition: Node = lobby.get_node("/root/SceneTransition")
	var on_complete := Callable(self, "schedule_unlock")
	transition.transition_completed.connect(on_complete)
	lobby.tree_exiting.connect(func():
		if transition.transition_completed.is_connected(on_complete):
			transition.transition_completed.disconnect(on_complete))

func style_button(target: Button, selected: bool, icon_id: String = "", font_size: int = 25) -> void:
	var style: StyleBoxTexture = active_style if selected else idle_style
	var frame := preload("res://src/ui/pixel_panel_skin.gd").button_style(style) as StyleBoxFlat
	frame.bg_color = Color("523068") if selected else Color("281832")
	for state in ["normal", "hover", "pressed", "disabled"]:
		target.add_theme_stylebox_override(state, frame)
	target.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	target.add_theme_font_size_override("font_size", font_size)
	target.add_theme_color_override("font_color", Color("fff0b5") if selected else Color("cbb6dd"))
	target.add_theme_color_override("font_hover_color", Color("fff6dc"))
	target.add_theme_color_override("font_pressed_color", Color("ffe390"))
	target.add_theme_color_override("font_disabled_color", Color("87768f"))
	target.add_theme_color_override("icon_normal_color", Color.WHITE if selected else Color(0.77, 0.66, 0.87))
	target.add_theme_constant_override("h_separation", 10)
	target.add_theme_constant_override("icon_max_width", 40)
	target.expand_icon = true
	if icons.has(icon_id):
		target.icon = icons[icon_id]

func place(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = left
	node.anchor_top = top
	node.anchor_right = right
	node.anchor_bottom = bottom
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

func button(parent: Control, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.custom_minimum_size.y = 64
	result.toggle_mode = true
	parent.add_child(result)
	result.pressed.connect(action)
	return result

func choose_difficulty(value: String) -> void:
	if value not in ["easy", "hard"] or (value == "hard" and not UNLOCKS.unlocked("hard", current_stage())):
		refresh()
		return
	if lobby._stage_transition_running:
		refresh()
		return
	difficulty = value
	lobby._refresh_stage_card()

func choose_perspective(value: String) -> void:
	if value not in ["demon", "hero"] or (value == "hero" and not UNLOCKS.unlocked("hero", current_stage())):
		refresh()
		return
	if lobby._stage_transition_running:
		refresh()
		return
	perspective = value
	lobby._refresh_stage_card()

func toggle_ranked() -> void:
	if not UNLOCKS.unlocked("rank", current_stage()):
		refresh()
		return
	if lobby._stage_transition_running:
		refresh()
		return
	ranked = not ranked
	lobby._close_stage_selector()
	lobby._refresh_stage_card()

func change_character(direction: int) -> void:
	if perspective == "hero" and not heroes.is_empty():
		hero_index = posmod(hero_index + direction, heroes.size())
	lobby._refresh_stage_card()

func open_characters() -> void:
	if not UNLOCKS.unlocked("hero", current_stage()):
		return
	var picker := AcceptDialog.new()
	picker.title = "용사 선택 · 미리보기"
	picker.min_size = Vector2i(650, 440)
	skin_dialog(picker)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	picker.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for index in heroes.size():
		var stage := heroes[index]
		var profile: Dictionary = lobby.HERO_PROFILES.get_profile(String(stage.hero_id))
		var option := button(list, String(profile.get("display_name", "용사")), func():
			hero_index = index
			lobby._refresh_stage_card()
			picker.queue_free())
		style_button(option, index == hero_index, "hero", 24)
	picker.confirmed.connect(picker.queue_free)
	picker.canceled.connect(picker.queue_free)
	lobby.add_child(picker)
	picker.popup_centered()

func skin_dialog(dialog: AcceptDialog) -> void:
	dialog.add_theme_stylebox_override("panel", lobby._make_style(Color("170e25"), Color("eac14d"), 3, 8))
	dialog.add_theme_font_size_override("font_size", 24)
	style_button(dialog.get_ok_button(), true, "", 24)

func request_data() -> Dictionary:
	return {"page": "ranked" if ranked else "stage", "perspective": perspective,
		"difficulty": difficulty, "stage_id": lobby.stage_ids[lobby.selected_stage_index],
		"hero_id": String(heroes[hero_index].hero_id) if not heroes.is_empty() else ""}

func blocks_entry() -> bool:
	if (ranked and not UNLOCKS.unlocked("rank", current_stage())) or (perspective == "hero" and not UNLOCKS.unlocked("hero", current_stage())) or (not ranked and difficulty == "hard" and not UNLOCKS.unlocked("hard", current_stage())):
		return true
	if not ranked and perspective == "demon" and difficulty == "easy":
		return false
	notice.dialog_text = "랭킹 매칭은 준비 중입니다. 실제 매칭은 아직 시작되지 않습니다." if ranked else "용사 시점과 어려움 난이도는 준비 중입니다. 현재는 마왕 · 쉬움으로 입장할 수 있습니다."
	notice.popup_centered(Vector2i(640, 180))
	return true

func refresh() -> void:
	# Changing stages or accounts must not carry an unlocked selection into a
	# locked context. UI-disabled states and direct handlers both enforce gates.
	if not UNLOCKS.unlocked("rank", current_stage()):
		ranked = false
	if not UNLOCKS.unlocked("hero", current_stage()):
		perspective = "demon"
	if not UNLOCKS.unlocked("hard", current_stage()):
		difficulty = "easy"
	for item in [[demon_button, perspective == "demon", "demon"], [hero_button, perspective == "hero", "hero"], [ranked_button, ranked, "rank"], [easy_button, difficulty == "easy", "easy"], [hard_button, difficulty == "hard", "hard"]]:
		item[0].set_pressed_no_signal(item[1])
		style_button(item[0], item[1], item[2])
	for item in [[hard_button, "hard"], [hero_button, "hero"], [ranked_button, "rank"]]:
		var locked := not UNLOCKS.unlocked(item[1], current_stage())
		item[0].disabled = locked
		item[0].tooltip_text = String(UNLOCK_DATA.RULES[item[1]].condition) if locked else ""
		if locked:
			item[0].icon = icons.lock
	schedule_unlock()
	difficulty_row.visible = not ranked
	character_button.visible = ranked and perspective == "hero"
	var section: Control = lobby.get_node("SafeArea/Layout/Content/MainTab/StageLayout/SectionHeaderBox")
	section.get_node("SectionTitle").text = "랭킹 매칭" if ranked else "침입자 기록"
	section.get_node("SectionSubtitle").text = "시점과 캐릭터를 선택하세요 · 매칭 기능 준비 중" if ranked else "대상 용사를 선택하고, 던전에 입장하세요."
	if not ranked:
		if perspective == "hero" or difficulty == "hard":
			lobby.enter_stage_button.text = "던전 입장 · 준비 중"
		return
	lobby.stage_selector_button.text = "SEASON · 준비 중"
	lobby.stage_selector_button.disabled = true
	lobby.stage_name_label.text = "마왕 매칭 대기실" if perspective == "demon" else "용사 매칭 대기실"
	var nickname := String(PROFILE.get_profile().get("nickname", ""))
	lobby.hero_name_label.text = nickname if not nickname.is_empty() else "게스트"
	if perspective == "demon":
		lobby._apply_portrait(PROFILE.portrait_path(), PROFILE.display_name())
	elif not heroes.is_empty():
		lobby._apply_portrait(String(heroes[hero_index].portrait_path), "용사")
	lobby.portrait_texture.self_modulate = Color.WHITE
	lobby.portrait_badge.visible = false
	lobby.portrait_texture.get_node("StageLock").visible = false
	lobby.stage_description_label.text = "마왕이 되어 상대 용사를 막아내세요.\n실시간 대전 · 시즌 점수는 준비 중입니다." if perspective == "demon" else "선택한 용사로 상대 마왕의 성에 도전하세요.\n실시간 대전 · 시즌 점수는 준비 중입니다."
	lobby.stage_status_label.text = "랭킹 점수\n미배치"
	lobby.stage_reward_label.text = "랭킹 등급\n미배치"
	lobby.stage_description_label.get_parent().get_node("RepeatReward").text = "닉네임\n" + lobby.hero_name_label.text
	lobby.enter_stage_button.text = "매칭 시작"
	lobby.enter_stage_button.disabled = false
	var navigable := perspective == "hero" and heroes.size() > 1
	lobby.prev_stage_button.disabled = not navigable
	lobby.next_stage_button.disabled = not navigable
	lobby._set_stage_arrow_visual(lobby.prev_stage_button, navigable)
	lobby._set_stage_arrow_visual(lobby.next_stage_button, navigable)

func current_stage() -> String:
	return String(lobby.stage_ids[lobby.selected_stage_index])

func schedule_unlock() -> void:
	if _unlock_scheduled or is_instance_valid(unlock_feedback):
		return
	_unlock_scheduled = true
	lobby.call_deferred("_check_mode_unlock_feedback")

func show_pending_unlock() -> void:
	_unlock_scheduled = false
	if is_instance_valid(unlock_feedback) or not lobby._presentation_ready or lobby.current_tab != "main" or UNLOCKS.is_test_override():
		return
	if lobby.get_node("/root/SceneTransition").is_transitioning() or lobby.get_node("/root/TutorialFlow").modal_visible or lobby.get_node("/root/TutorialFlow").locks_lobby():
		return
	var stage_id := current_stage()
	var owner := PROFILE.SCOPE.user_id + ":" + PROFILE.SCOPE.guest_directory
	for key in UNLOCK_DATA.ORDER:
		var session_key := owner + ":" + UNLOCK_DATA.announcement_key(key, stage_id)
		if not UNLOCKS.unlocked(key, stage_id) or UNLOCKS.announcement_seen(key, stage_id) or _announced_this_session.has(session_key):
			continue
		unlock_feedback = UNLOCK_FEEDBACK.new()
		lobby.add_child(unlock_feedback)
		unlock_feedback.dismissed.connect(func():
			if owner == PROFILE.SCOPE.user_id + ":" + PROFILE.SCOPE.guest_directory:
				_announced_this_session[session_key] = true
				if not UNLOCKS.mark_announced(key, stage_id):
					push_warning("Mode unlock announcement could not be saved; retry next session.")
			unlock_feedback = null
			schedule_unlock())
		var description := String(UNLOCK_DATA.RULES[key].condition).replace("후 개방", "완료")
		if key == "hard":
			description = "쉬움 Stage %d 클리어 완료" % int(stage_id.trim_prefix("stage_"))
		unlock_feedback.present(String(UNLOCK_DATA.RULES[key].name), description)
		return
