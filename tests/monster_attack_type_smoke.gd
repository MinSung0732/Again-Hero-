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
	lobby.free()
	print("MONSTER_ATTACK_TYPE_SMOKE_OK" if not failed else "MONSTER_ATTACK_TYPE_SMOKE_FAILED")
	quit(1 if failed else 0)
