extends SceneTree
## Isolated CPU cost of the shared helper. Does not measure whole-frame FPS.
const HIT := preload("res://src/systems/monster_hit_context.gd")
const WEAPONS := preload("res://src/hero_mode/hero_weapon_runtime.gd")
class Target extends Node:
	var current_hp := 100000000
	func take_damage(amount: int) -> bool: current_hp -= amount; return true
class Arena extends Node:
	var hero: Node
const COUNT := 12000
func _initialize() -> void: run.call_deferred()
func work(helper,target,source) -> void:
	for index in COUNT: helper.hit(target,1,"ranged",source)
func run() -> void:
	var old := GDScript.new(); old.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase2/monster_hit_context_before.gd.txt")
	if old.reload() != OK: quit(1); return
	var h = load("res://src/hero/hero.gd").new(); var r = WEAPONS.new(); h.player_weapons = r; r.hero = h; h.max_hp = 100; h.current_hp = 100
	var arena := Arena.new(); arena.hero = h; root.add_child(arena)
	var shot := Node.new(); arena.add_child(shot); shot.add_to_group("hero_projectiles")
	var target := Target.new(); var rows: Array = []
	for source in [null,h,shot]:
		for siphon in [0.0,.1]:
			r.passive_siphon = siphon
			var before: Array = []; var after: Array = []
			work(old,target,source); work(HIT,target,source)
			for trial in 7:
				for optimized in ([false,true] if trial%2 == 0 else [true,false]):
					var begin := Time.get_ticks_usec(); work(HIT if optimized else old,target,source)
					(after if optimized else before).append((Time.get_ticks_usec()-begin)/1000.0)
			before.sort(); after.sort()
			var row := {"source":"none" if source == null else "hero" if source == h else "projectile","siphon":siphon,"hits_per_trial":COUNT,"runs":7,"before_median_ms":before[3],"after_median_ms":after[3],"before_samples_ms":before,"after_samples_ms":after}
			rows.append(row); print("PHASE2_HIT_BENCH ",JSON.stringify(row))
	var file := FileAccess.open("user://combat_phase2_hit_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"cpu_only":true,"rows":rows},"\t")); file.close()
	h.player_weapons = null; r.hero = null; h.free(); target.free(); arena.free(); quit()
