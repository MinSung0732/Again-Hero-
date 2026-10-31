extends SceneTree
## Fear must ignore a summoned combat target lacking Hero-only status properties.
const GUMIHO := preload("res://src/monsters/gumiho.gd")
var checks := 0
var failures := 0

class SummonedTarget extends Node2D:
	var current_hp := 100

class FearTarget extends Node2D:
	var current_hp := 100
	var fear_immunity_timer := 0.0
	var received := 0
	func apply_fear(_source: Node2D, _duration: float, _speed: float) -> void:
		received += 1
		set_meta("fear_active",true)

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("GUMIHO_FEAR: "+label)

func run() -> void:
	var gumiho := GUMIHO.new()
	gumiho.current_hp = gumiho.max_hp
	var summon := SummonedTarget.new()
	gumiho.hero = summon
	check(not gumiho.try_cast_elite_skill({"id":"elite_gumiho_fear"}),"summon lacking fear API is ignored without a float(null) error")
	var healthy := FearTarget.new()
	gumiho.hero = healthy
	healthy.fear_immunity_timer = 5.0
	check(not gumiho.try_cast_elite_skill({"id":"elite_gumiho_fear"}) and healthy.received == 0,"real immunity still blocks fear")
	healthy.fear_immunity_timer = 0.0
	check(gumiho.try_cast_elite_skill({"id":"elite_gumiho_fear"}) and healthy.received == 1,"normal Hero fear application preserved")
	check(not healthy.has_meta("incoming_fear_immunity"),"temporary immunity metadata restored")
	healthy.current_hp = 0
	check(not gumiho.try_cast_elite_skill({"id":"elite_gumiho_fear"}),"dead targets are not feared")
	gumiho.free()
	summon.free()
	healthy.free()
	print("GUMIHO_FEAR checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
