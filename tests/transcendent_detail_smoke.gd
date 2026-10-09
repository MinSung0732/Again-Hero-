extends SceneTree
const DATA := preload("res://src/data/transcendent_detail_catalog.gd")
const VIEW := preload("res://src/ui/transcendent_monster_detail_view.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TRANSCENDENT_DETAIL: "+message)
func run() -> void:
	var parent := VBoxContainer.new()
	parent.size = Vector2(660,1600)
	root.add_child(parent)
	var view := VIEW.new()
	view.install(parent)
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	# Bind only actual detail nodes; avoid unrelated Lobby startup/network/UI warmup.
	for property in ["title","normal_badge","elite_badge","normal_name","elite_name","normal_portrait","elite_portrait","normal_stats","specials","elite_stats","elite_skills"]:
		var paths := {
			"title":"MonsterDetailOverlay/Panel/Margin/VBox/Header/Title",
			"normal_badge":"NormalPanel/Margin/VBox/Badge","elite_badge":"ElitePanel/Margin/VBox/Badge",
			"normal_name":"NormalPanel/Margin/VBox/Name","elite_name":"ElitePanel/Margin/VBox/Name",
			"normal_portrait":"NormalPanel/Margin/VBox/PortraitFrame/PortraitMargin/Portrait","elite_portrait":"ElitePanel/Margin/VBox/PortraitFrame/PortraitMargin/Portrait",
			"normal_stats":"NormalPanel/Margin/VBox/Stats","specials":"NormalPanel/Margin/VBox/Specials",
			"elite_stats":"ElitePanel/Margin/VBox/Stats","elite_skills":"ElitePanel/Margin/VBox/Skills",
		}
		var path: String = paths[property]
		if property != "title": path = "MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/"+path
		lobby.set("monster_detail_"+property,lobby.get_node(path))
	for id in DATA.ENTRIES:
		view.present(id)
		check(view.unlock.text.contains("전투당 한 번"),"once-per-battle condition "+id)
		check(view.upgrades.text.contains("5초월") and DATA.ENTRIES[id].upgrades.size()==5,"all five upgrades "+id)
		check(DATA.ENTRIES[id].skills.any(func(skill): return skill.kind == "패시브"),"passive included "+id)
		lobby._populate_monster_detail(id)
		check(lobby._transcendent_detail.root.visible and not lobby.monster_detail_specials.visible,"dedicated detail replaces special augments "+id)
		check(not lobby.monster_detail_specials.get_parent().get_node("SpecialTitle").visible,"special heading hidden "+id)
		check(not lobby.get_node("MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll/Compare/ElitePanel").visible,"elite panel hidden "+id)
		check(not lobby.monster_detail_normal_stats.text.contains("초월1:") and not lobby.monster_detail_normal_stats.text.contains("코스트"),"old long description removed "+id)
	lobby._populate_monster_detail("slime")
	check(not lobby._transcendent_detail.root.visible and lobby.monster_detail_specials.visible,"ordinary detail restores special section")
	check(lobby.monster_detail_specials.get_parent().get_node("SpecialTitle").visible,"ordinary heading restored")
	view.present("not_registered")
	check(view.rows.all(func(row): return not row.visible),"unknown content clears reused skill rows")
	lobby.free()
	parent.free()
	print("TRANSCENDENT_DETAIL: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
