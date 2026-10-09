extends SceneTree

const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func run() -> void:
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	var expected := {"slime": "melee", "spider": "ranged", "orc": "melee", "bomb_rat": "self_destruct"}
	for id in CATALOG.ORDER:
		var type := CATALOG.get_attack_type(id)
		check(CATALOG.ATTACK_TYPE_LABELS.has(type), "Missing attack type: " + id)
		if expected.has(id):
			check(type == expected[id], "Incorrect original monster attack type: " + id)
		var data := CATALOG.get_monster(id)
		var stats := CATALOG.get_base_stats(id)
		var role := CATALOG.get_role_label(String(data.role))
		var label := CATALOG.get_attack_type_label(type)
		var normal: String = lobby._build_normal_detail_text(id, role, data, stats)
		var elite: String = lobby._build_elite_detail_text(id, role, data, stats, {})
		check(normal.split("\n")[0].contains(" · " + label), "Normal detail missing type: " + id)
		check(elite.split("\n")[0].contains(" · " + label), "Elite detail missing type: " + id)
		for text in [normal,elite]:
			var previous := -1
			for stat in ["체력","공격","공속","기동","사거리"]:
				var marker: String = "[color=#d8cedd]"+stat+"[/color]"
				check(text.count(marker)==1,"exactly one stat row "+id+":"+stat)
				check(text.find(marker)>previous,"stable stat order "+id+":"+stat)
				previous = text.find(marker)
			check(not text.contains("크기 ×"),"no visual scale description "+id)
		if String(data.role) in ["control","controller"]:
			check(role=="제어","control aliases share Korean label "+id)
	check(CATALOG.get_role_label("control")=="제어" and CATALOG.get_role_label("controller")=="제어","all control aliases localized")
	lobby.free()
	print("MONSTER_ATTACK_TYPE_SMOKE_OK" if not failed else "MONSTER_ATTACK_TYPE_SMOKE_FAILED")
	quit(1 if failed else 0)
