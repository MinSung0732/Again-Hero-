extends SceneTree
const FX := preload("res://src/online/fx_motion.gd")
const MIRROR := preload("res://src/online/primitive_mirror.gd")
const RULES := preload("res://src/online/match_rules.gd")
var failed := false
func check(value: bool, message: String) -> void:
	if not value: push_error(message); failed = true
func _initialize() -> void:
	var fx = FX.new()
	fx.begin(); fx.put(1,Vector2.ZERO); fx.finish()
	fx.begin(); fx.put(1,Vector2(100,0)); fx.put(2,Vector2(30,0)); fx.finish()
	fx.advance(RULES.SNAPSHOT_INTERVAL * 0.5)
	check(fx.position(1,Vector2.ZERO).is_equal_approx(Vector2(50,0)),"halfway")
	check(fx.position(2,Vector2.ZERO) == Vector2(30,0),"new id")
	fx.begin(); fx.put(2,Vector2(1000,0)); fx.finish()
	check(fx.position(1,Vector2(-1,0)) == Vector2(-1,0),"removed id")
	check(fx.position(2,Vector2.ZERO) == Vector2(1000,0),"large jump")
	var mirror = MIRROR.new()
	var rows := []
	MIRROR.append(rows,"circle",Vector2.ZERO,0,10,Color.WHITE,0,PackedVector2Array(),1)
	mirror.replace(rows)
	rows.clear()
	MIRROR.append(rows,"circle",Vector2(100,0),0,10,Color.WHITE,0,PackedVector2Array(),1)
	mirror.replace(rows)
	mirror.motion.advance(RULES.SNAPSHOT_INTERVAL * 0.5)
	check(mirror.motion.position(1,Vector2.ZERO).is_equal_approx(Vector2(50,0)),"primitive halfway")
	var count: int = mirror.parsed.size()
	for i in 10: mirror.motion.advance(0.01); check(mirror.parsed.size() == count,"buffer size")
	quit(1 if failed else 0)
