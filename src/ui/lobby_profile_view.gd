extends RefCounted

const PROFILE := preload("res://src/systems/player_profile.gd")
const STORE := preload("res://src/systems/profile_cosmetic_store.gd")
const CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const APPEARANCE := preload("res://src/systems/demon_appearance_store.gd")
const APPEARANCES := preload("res://src/data/demon_appearance_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const DRAG_BUTTON := preload("res://src/ui/drag_safe_button.gd")

var settings_ref: WeakRef
var settings: RefCounted:
	get:
		return settings_ref.get_ref() as RefCounted
var lobby: Control
var root: VBoxContainer
var title_plate: PanelContainer
var scroll: ScrollContainer
var card: Control
var banner: TextureRect
var portrait: TextureRect
var nickname: Label
var rename_button: Button
var gender_button: Button
var gender_dialog: Control
var actions := {}
var gallery: Button
var reserved: Control
var picker: ColorRect
var picker_title: Label
var picker_notice: Label
var picker_buttons := {}
var picker_slot := ""
var picker_owner := ""
var textures := {}
var shade: GradientTexture2D
var _locked_texture: Texture2D
var icon_picker: RefCounted
var banner_picker: RefCounted

func install(owner: RefCounted, parent: Control) -> void:
	settings_ref = weakref(owner)
	lobby = settings.lobby
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.055, 0.025, 0.09, 0))
	gradient.set_color(1, Color(0.055, 0.025, 0.09, 0.97))
	shade = GradientTexture2D.new()
	shade.gradient = gradient
	shade.fill_from = Vector2(0.25, 0)
	shade.fill_to = Vector2(0.82, 0)
	root = VBoxContainer.new()
	root.name = "ProfileContent"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	parent.add_child(root)
	var title := Label.new()
	title.text = "프로필"
	title_plate = settings._title_plate(lobby.other_tab, title)
	title_plate.name = "ProfileTitlePlate"
	scroll = ScrollContainer.new()
	scroll.name = "ProfileScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	root.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	scroll.add_child(column)
	_build_card(column)
	rename_button = _button(column, "마왕 이름 변경 (계정 연동 %d회)" % PROFILE.NAMES.LINKED_RENAMES, false)
	rename_button.name = "NicknameChange"
	rename_button.custom_minimum_size.y = 96
	rename_button.connect("confirmed", _open_name_change)
	gender_button = _button(column, PROFILE.GENDERS.ACTION % PROFILE.GENDERS.LINKED_CHANGES, false)
	gender_button.name = "GenderChange"
	gender_button.custom_minimum_size.y = 96
	gender_button.connect("confirmed", _open_gender_change)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	column.add_child(grid)
	for entry in CATALOG.ACTIONS:
		var id := String(entry[0])
		var button := _button(grid, String(entry[1]) + ("\n준비 중" if id == "title" else "  ›"), id == "title")
		button.name = id.to_pascal_case() + "Change"
		button.custom_minimum_size.y = 126
		button.icon = _texture("res://assets/art/UI/profile_v1/icon_%s.svg" % entry[2])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 64)
		actions[id] = button
		if id != "title":
			button.connect("confirmed", open_picker.bind(id))
	gallery = _button(column, "", true)
	gallery.name = "IllustrationGallery"
	gallery.custom_minimum_size.y = 182
	var gallery_viewport := _art_viewport(gallery)
	var gallery_art := _image(gallery_viewport)
	gallery_art.name = "GalleryArt"
	gallery_art.modulate = Color(0.4, 0.3, 0.5)
	_full(gallery_art)
	_full_shade(gallery_viewport)
	var gallery_text := _label(gallery, "일러스트 감상", 36, Color("f2ddff"))
	_rect(gallery_text, Vector2(30, 32), Vector2(460, 56))
	var gallery_info := _label(gallery, "수집한 일러스트를 감상하세요. · 준비 중", 23)
	_rect(gallery_info, Vector2(30, 96), Vector2(530, 52))
	_frame(gallery)
	reserved = Control.new()
	reserved.name = "ReservedFeatureSpace"
	reserved.custom_minimum_size.y = 182
	reserved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(reserved)
	_build_picker()
	hide()

func _build_card(parent: Control) -> void:
	card = Control.new()
	card.name = "ProfileCard"
	card.custom_minimum_size.y = 650
	parent.add_child(card)
	var banner_viewport := _art_viewport(card)
	banner = _image(banner_viewport)
	banner.name = "ProfileBanner"
	_full(banner)
	_full_shade(banner_viewport)
	var info := Control.new()
	info.name = "ProfileInformation"
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(info)
	info.anchor_left = 1
	info.anchor_right = 1
	info.offset_left = -330
	info.offset_right = -24
	info.offset_top = 90
	info.offset_bottom = 620
	var portrait_box := PanelContainer.new()
	portrait_box.name = "PortraitFrame"
	portrait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_theme_stylebox_override("panel", FRAMES.style("shop_featured_frame", 10))
	info.add_child(portrait_box)
	_rect(portrait_box, Vector2(80, 0), Vector2(152, 152))
	portrait = _image(portrait_box)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var edit := _button(info, "", false)
	edit.name = "PortraitEdit"
	edit.icon = _texture("res://assets/art/UI/profile_v1/icon_edit.svg")
	edit.expand_icon = true
	edit.add_theme_constant_override("icon_max_width", 32)
	_rect(edit, Vector2(234, 72), Vector2(68, 80))
	edit.connect("confirmed", open_picker.bind("avatar"))
	nickname = _label(info, "", 36, Color("e4c5ff"))
	nickname.autowrap_mode = TextServer.AUTOWRAP_OFF
	nickname.clip_text = true
	nickname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rect(nickname, Vector2(0, 174), Vector2(306, 64))
	var title := _label(info, "칭호 · 준비 중", 28, Color("f1d798"))
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rect(title, Vector2(0, 258), Vector2(306, 60))
	var line := ColorRect.new()
	line.color = Color("99713d")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(line)
	_rect(line, Vector2(14, 328), Vector2(278, 2))
	var rank := _label(info, "랭킹 티어\n준비 중\n\n랭킹 점수\n준비 중", 26, Color("ead9fa"))
	rank.autowrap_mode = TextServer.AUTOWRAP_OFF
	rank.name = "RankingPlaceholder"
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rect(rank, Vector2(0, 350), Vector2(306, 186))
	_frame(card)

func _build_picker() -> void:
	icon_picker = preload("res://src/ui/lobby_profile_icon_picker.gd").new()
	icon_picker.install(self)
	banner_picker = preload("res://src/ui/lobby_profile_icon_picker.gd").new()
	banner_picker.install(self, "banner")
	picker = ColorRect.new()
	picker.name = "ProfileCosmeticPicker"
	picker.color = Color(0, 0, 0, 0.85)
	picker.z_index = 100
	lobby.add_child(picker)
	_full(picker)
	var center := CenterContainer.new()
	picker.add_child(center)
	_full(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 800
	panel.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 32))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)
	picker_title = _label(column, "", 36, Color("ffe3a0"))
	picker_notice = _label(column, "", 25)
	picker_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	column.add_child(grid)
	var ids := CATALOG.ids()
	for appearance_id in APPEARANCES.ORDER:
		if appearance_id not in ids: ids.append(appearance_id)
	for id in ids:
		var button := _button(grid, "", false)
		button.custom_minimum_size = Vector2(350, 292)
		button.expand_icon = true
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 280)
		picker_buttons[id] = button
		button.connect("confirmed", _choose.bind(id))
	var close := _button(column, "닫기", false)
	close.custom_minimum_size.y = 88
	close.connect("confirmed", close_picker)
	picker.hide()

func open_picker(slot: String) -> void:
	if slot not in ["avatar", "banner", "representative"] or _blocked():
		return
	if slot == "avatar":
		picker.hide()
		banner_picker.close()
		icon_picker.open()
		return
	icon_picker.close()
	if slot == "banner":
		picker.hide()
		banner_picker.open()
		return
	banner_picker.close()
	picker_slot = slot
	picker_owner = _scope_key()
	picker_title.text = {"avatar": "초상화 변경", "banner": "배너 변경", "representative": "대표 캐릭터 변경"}[slot]
	picker_notice.text = {"avatar": "프로필 카드의 작은 초상화에 적용됩니다.", "banner": "프로필 카드의 큰 배경 일러스트에 적용됩니다.", "representative": "대표 마왕 외형과 이후 대사에 적용됩니다.\n계정 성별·닉네임은 유지됩니다."}[slot]
	var selected := PROFILE.appearance_id() if slot == "representative" else STORE.selected_id(slot)
	var available := APPEARANCE.owned_ids() if slot == "representative" else STORE.choices(slot)
	for id in picker_buttons:
		var button: Button = picker_buttons[id]
		var initial := not String(APPEARANCES.get_entry(id).get("initial_gender", "")).is_empty()
		var locked: bool = id not in available
		button.visible = not locked or initial
		if not button.visible:
			continue
		var display_name := String(APPEARANCES.get_entry(id).get("name",id)) if slot == "representative" else CATALOG.display_name(id)
		button.text = display_name + ("\n잠김 · 미보유" if locked else ("\n사용 중" if id == selected else "\n선택"))
		button.icon = _lock_texture() if locked else _texture(APPEARANCES.path(id,"avatar") if slot == "representative" else CATALOG.path(id, "banner" if slot == "banner" else "avatar"))
		button.tooltip_text = "처음 선택한 성별의 기본 마왕만 보유합니다." if locked else ""
		button.disabled = locked or id == selected
	picker.show()

func _lock_texture() -> Texture2D:
	if _locked_texture == null:
		var image := Image.new()
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" shape-rendering="crispEdges"><path d="M24 44V20H36V8H60V20H72V44H60V20H36V44Z" fill="#cfb57b"/><path d="M12 40H84V88H12Z" fill="#cfb57b"/><path d="M40 52H56V68H52V80H44V68H40Z" fill="#37253e"/></svg>')
		_locked_texture = ImageTexture.create_from_image(image)
	return _locked_texture

func _choose(id: String) -> void:
	if picker_owner != _scope_key() or _blocked() or not picker.visible:
		close_picker()
		return
	var saved: bool = equip_representative(id) if picker_slot == "representative" else STORE.select(picker_slot, id)
	if not saved:
		picker_notice.text = "변경을 저장하지 못했습니다. 다시 시도해 주세요."
		return
	refresh()
	close_picker()

func equip_representative(id: String) -> bool:
	if _blocked() or not APPEARANCE.equip(id):
		return false
	settings._sync_account()
	lobby._refresh_stage_card()
	return true

func close_picker() -> void:
	picker.hide()
	picker_slot = ""
	if icon_picker != null: icon_picker.close()
	if banner_picker != null: banner_picker.close()

func _scope_key() -> String:
	return PROFILE.SCOPE.user_id + ":" + PROFILE.SCOPE.guest_directory

func _blocked() -> bool:
	var cloud := lobby.get_node("/root/CloudStore")
	return cloud.busy or cloud.conflict

func refresh() -> void:
	gender_button.visible = PROFILE.can_change_gender()
	gender_button.disabled = _blocked() or is_instance_valid(gender_dialog)
	rename_button.visible = PROFILE.can_rename()
	rename_button.disabled = _blocked()
	nickname.text = String(PROFILE.get_profile().get("nickname", ""))
	if nickname.text.is_empty():
		nickname.text = "마왕"
	banner.texture = _texture(CATALOG.path(STORE.selected_id("banner"), "banner"))
	portrait.texture = _texture(CATALOG.path(STORE.selected_id("avatar"), "avatar"))
	(gallery.get_node("ArtViewport/GalleryArt") as TextureRect).texture = banner.texture
	for id in ["avatar", "banner", "representative"]:
		actions[id].disabled = _blocked()
	(card.get_node("ProfileInformation/PortraitEdit") as Button).disabled = _blocked()
	if picker.visible and (picker_owner != _scope_key() or _blocked()):
		close_picker()
	if icon_picker != null: icon_picker.refresh_state()
	if banner_picker != null: banner_picker.refresh_state()

func _open_name_change() -> void:
	if _blocked() or not PROFILE.can_rename(): return
	var view := preload("res://src/ui/player_prologue.gd").new()
	view.rename_only = true
	lobby.add_child(view)
	view.finished.connect(func(): view.queue_free(); refresh())

func _open_gender_change() -> void:
	if _blocked() or not PROFILE.can_change_gender() or is_instance_valid(gender_dialog): return
	var view := preload("res://src/ui/profile_gender_dialog.gd").new()
	gender_dialog = view
	lobby.add_child(view)
	view.finished.connect(func():
		view.queue_free()
		gender_dialog = null
		refresh()
		if settings.has_method("_sync_account"): settings._sync_account()
	)
	refresh()

func show() -> void:
	refresh()
	root.show()
	title_plate.show()
	scroll.scroll_vertical = 0

func hide() -> void:
	root.hide()
	title_plate.hide()
	close_picker()

func _texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not textures.has(path):
		var warmup := lobby.get_node("/root/PresentationWarmup")
		var value: Texture2D = warmup.get_texture(path)
		if value == null and ResourceLoader.exists(path):
			value = load(path) as Texture2D
		if value == null and path.get_extension() == "png":
			var image := Image.new()
			if image.load(path) == OK:
				value = ImageTexture.create_from_image(image)
		textures[path] = value
	return textures[path] as Texture2D

func _button(parent: Control, text: String, disabled: bool) -> Button:
	var button := DRAG_BUTTON.new()
	button.text = text
	button.disabled = disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("e7c8ff"))
	button.add_theme_color_override("font_disabled_color", Color("bca7cb"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 14, Color("cab5d4") if state == "disabled" else Color.WHITE))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(button)
	return button

func _art_viewport(parent: Control) -> Control:
	var viewport := Control.new()
	viewport.name = "ArtViewport"
	viewport.clip_contents = true
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(viewport)
	_full(viewport)
	viewport.offset_left = 16
	viewport.offset_top = 16
	viewport.offset_right = -16
	viewport.offset_bottom = -16
	return viewport

func _image(parent: Control) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func _label(parent: Control, text: String, font_size: int, color := Color("cebadb")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _frame(parent: Control) -> void:
	var frame := Panel.new()
	var style := FRAMES.style("shop_featured_frame", 8)
	style.draw_center = false
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	_full(frame)

func _full_shade(parent: Control) -> void:
	var overlay := _image(parent)
	overlay.texture = shade
	_full(overlay)

func _full(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _rect(control: Control, position: Vector2, size: Vector2) -> void:
	control.position = position
	control.size = size
