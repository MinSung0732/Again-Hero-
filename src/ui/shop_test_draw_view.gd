extends RefCounted

const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var selected_id := ""
var section: VBoxContainer
var selector: OptionButton
var monster_ids: Array[String] = [""]

func install(lobby: Control) -> void:
	var content := lobby.get_node(lobby.SHOP_STOREFRONT_ART.CONTENT.trim_suffix("/"))
	section = VBoxContainer.new()
	section.name = "TestDrawSelection"
	section.add_theme_constant_override("separation", 8)
	content.add_child(section)
	content.move_child(section, content.get_node("MonsterSection").get_index())
	var label := Label.new()
	label.text = "테스트 소환 · 일반/픽업 공통"
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(label)
	selector = OptionButton.new()
	selector.custom_minimum_size.y = 88
	section.add_child(selector)
	lobby._apply_lobby_button_skin(selector, false, 28)
	selector.get_popup().add_theme_font_size_override("font_size", 28)
	selector.add_item("기존 확률로 소환")
	for id in SHOP.get_monster_pool("transcendent"):
		monster_ids.append(String(id))
		selector.add_item("초월 확정 · %s" % MONSTERS.get_monster_name(id))
	selector.item_selected.connect(_select)
	var note := Label.new()
	note.text = "확정 선택 시 10+1회도 전부 해당 몬스터 획득\n테스트 저장에만 지급 · 골드 차감 없음"
	note.add_theme_font_size_override("font_size", 23)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(note)
	refresh()

func refresh() -> void:
	if not is_instance_valid(section):
		return
	section.visible = LocalTestMode.has_all_monsters_unlocked() and not TutorialFlow.locks_lobby()
	if not section.visible:
		selected_id = ""
		selector.select(0)

func _select(index: int) -> void:
	if index < 0 or index >= monster_ids.size() or TutorialFlow.locks_lobby():
		return
	selected_id = LocalTestMode.forced_gacha_monster(monster_ids[index])
	if selected_id.is_empty():
		selector.select(0)
