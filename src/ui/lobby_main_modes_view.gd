extends RefCounted

# Preview state is session-local: it must not unlock stages or save fake rankings.
const PROFILE := preload("res://src/systems/player_profile.gd")
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

func install(host) -> void:
	lobby = host
	var top: Control = lobby.hero_name_label.get_parent()
	var bottom: Control = lobby.stage_description_label.get_parent()
	difficulty_row = HBoxContainer.new()
	difficulty_row.name = "DifficultySelector"
	top.add_child(difficulty_row)
	place(difficulty_row, 0.23, 0.0, 0.77, 0.065)
	easy_button = button(difficulty_row, "쉬움", func(): choose_difficulty("easy"))
	hard_button = button(difficulty_row, "어려움", func(): choose_difficulty("hard"))
	mode_row = HBoxContainer.new()
	mode_row.name = "MainModeSelector"
	mode_row.add_theme_constant_override("separation", 12)
	bottom.add_child(mode_row)
	place(mode_row, 0.03, 0.81, 0.97, 1.02)
	var sides := HBoxContainer.new()
	sides.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	lobby._apply_lobby_button_skin(character_button, false, 22)
	character_button.pressed.connect(open_characters)
	notice = AcceptDialog.new()
	notice.title = "준비 중"
	skin_dialog(notice)
	lobby.add_child(notice)
	for id in lobby.stage_ids:
		var stage: Dictionary = lobby.STAGE_CATALOG.get_stage(id)
		if lobby.STAGE_PROGRESS.is_stage_unlocked(int(stage.get("number", 999))):
			heroes.append(stage)

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
	if lobby._stage_transition_running:
		refresh()
		return
	difficulty = value
	lobby._refresh_stage_card()

func choose_perspective(value: String) -> void:
	if lobby._stage_transition_running:
		refresh()
		return
	perspective = value
	lobby._refresh_stage_card()

func toggle_ranked() -> void:
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
	var picker := AcceptDialog.new()
	picker.title = "용사 선택 · 미리보기"
	picker.min_size = Vector2i(650, 440)
	skin_dialog(picker)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
		lobby._apply_lobby_button_skin(option, index == hero_index, 22)
	picker.confirmed.connect(picker.queue_free)
	picker.canceled.connect(picker.queue_free)
	lobby.add_child(picker)
	picker.popup_centered()

func skin_dialog(dialog: AcceptDialog) -> void:
	dialog.add_theme_stylebox_override("panel", lobby._make_style(Color("170e25"), Color("eac14d"), 3, 8))
	dialog.add_theme_font_size_override("font_size", 24)
	lobby._apply_lobby_button_skin(dialog.get_ok_button(), false, 22)

func request_data() -> Dictionary:
	return {"page": "ranked" if ranked else "stage", "perspective": perspective,
		"difficulty": difficulty, "stage_id": lobby.stage_ids[lobby.selected_stage_index],
		"hero_id": String(heroes[hero_index].hero_id) if not heroes.is_empty() else ""}

func blocks_entry() -> bool:
	if not ranked and perspective == "demon" and difficulty == "easy":
		return false
	notice.dialog_text = "랭킹 매칭은 준비 중입니다. 실제 매칭은 아직 시작되지 않습니다." if ranked else "용사 시점과 어려움 난이도는 준비 중입니다. 현재는 마왕 · 쉬움으로 입장할 수 있습니다."
	notice.popup_centered(Vector2i(640, 180))
	return true

func refresh() -> void:
	for item in [[demon_button, perspective == "demon"], [hero_button, perspective == "hero"], [ranked_button, ranked], [easy_button, difficulty == "easy"], [hard_button, difficulty == "hard"]]:
		item[0].set_pressed_no_signal(item[1])
		lobby._apply_lobby_button_skin(item[0], item[1], 21)
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
