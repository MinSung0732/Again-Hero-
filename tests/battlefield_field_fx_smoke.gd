extends SceneTree
const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
const GUIDE := preload("res://src/data/ranked_rules_guide.gd")

class Hero:
	extends Node2D
	var current_hp := 1000
	var max_hp := 1000
	var is_dying := false
	var common_attack_speed_bonus := 0.0
	func take_status_damage(amount: int) -> void: current_hp -= amount
	func heal_direct(amount: int) -> void: current_hp = mini(max_hp,current_hp + amount)
	func set_player_move_input(_value: Vector2) -> void: pass

class Battle:
	extends Node
	var hero = Hero.new()
	func set_external_pause(_value: bool) -> void: pass

func check(value: bool, message: String) -> void:
	if not value: push_error(message); quit(1); assert(value, message)

func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(not GUIDE.sections().is_empty(), "ranked guide renders")
	check(str(GUIDE.sections()).contains("랭킹 매칭"), "ranked guide label")
	var field = FIELD.new(); root.add_child(field)
	var room = ROOM.new(); root.add_child(room)
	room.battle = Battle.new(); root.add_child(room.battle)
	room.running = true
	field.configure("stage_1", Vector2(3200,3200), "castle")
	check(field.effect_areas.is_empty(), "castle has no effects")
	for theme in ["cursed_swamp", "sunlit_meadow"]:
		field.configure("stage_1", Vector2(3200,3200), theme)
		room.field_areas = field.effect_areas
		for item in THEMES.get_theme(theme).layout:
			if not item.has("effect"): continue
			var expected: Vector2 = item.pos * 3200.0
			var found := false
			for area in room.field_areas:
				if area.id == item.effect and area.position.is_equal_approx(expected) and area.radius == item.radius: found = true
			check(found, "effect position " + theme + " " + item.effect)
		var count: int = room.field_areas.size()
		for id in THEMES.EFFECTS:
			var area: Dictionary = {}
			for candidate in room.field_areas:
				if candidate.id == id: area = candidate; break
			if area.is_empty(): continue
			room.battle.hero.position = Vector2(-1000,-1000); room._update_field_effects()
			room.battle.hero.current_hp = 500
			room.battle.hero.position = area.position
			room.field_elapsed = 0.0; room.step(0.24)
			check(room.field_fx.is_empty(), "no early tick " + id)
			room.step(0.01)
			check(room.field_fx.has(id), "inside " + id)
			var stat: String = THEMES.EFFECTS[id].stat
			if stat == "move_speed": check(is_equal_approx(room.battle.hero.get_meta("field_move_multiplier"),0.75), "slow")
			if stat == "attack_speed": check(is_equal_approx(room.battle.hero.common_attack_speed_bonus,0.15), "haste")
			if stat == "damage_per_second": check(room.battle.hero.current_hp < 500, "damage")
			if stat == "heal_per_second": check(room.battle.hero.current_hp > 500, "heal")
			if stat == "damage_per_second" or stat == "heal_per_second":
				for tick in 3: room.step(0.25)
				check(room.battle.hero.current_hp == (490 if stat == "damage_per_second" else 510), "one second rate " + id)
			room.battle.hero.position = Vector2(-1000,-1000); room.step(0.25)
			check(room.field_fx.is_empty() and is_equal_approx(room.battle.hero.get_meta("field_move_multiplier"),1.0) and is_zero_approx(room.battle.hero.common_attack_speed_bonus), "exit " + id)
			check(room.field_areas.size() == count, "areas remain cached")
	room.finish("hero", "test")
	room.battle.free(); room.free(); field.free()
	print("PASS battlefield field effects")
	quit()
