extends SceneTree
const DELIVERY := preload("res://src/hero_mode/hero_weapon_delivery_runtime.gd")
const EVOLUTION := preload("res://src/hero_mode/hero_weapon_evolution_runtime.gd")
const PRIMITIVES := preload("res://src/online/primitive_mirror.gd")
const SAMPLE := preload("res://src/online/presentation_snapshot.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
class Authority extends RefCounted:
	var actor := Node2D.new()
	func resolve_battle_entity(_handle: Vector3i) -> Node2D: return actor
class Host extends RefCounted:
	var hero := Node2D.new()
	var delivery: RefCounted
	var evolution: RefCounted
	var art: Dictionary = {}
	var authority: RefCounted
	var fields: Array = []
	var effects: Array = []
	func _loop_frame(frames: Array,_clock: float) -> Texture2D: return frames[0]
	func _frame(frames: Array,_progress: float) -> Texture2D: return frames[0]
	func _loop_progress(_frames: Array,_clock: float) -> float: return 0.0
var failures := 0
var checks := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var host := Host.new()
	host.delivery = DELIVERY.new(); host.delivery.install(host)
	var slot: Dictionary = host.delivery.slots[0]
	slot.merge({"left":2.0,"mode":"zone","origin":Vector2(120,240),"radius":70.0,"color":Color(.2,.3,.4,.7)},true)
	var commands := PRIMITIVES.capture(host)
	check(commands.size()==2 and PRIMITIVES.valid(commands),"active delivery area mirrored through existing wire")
	check(commands[0][1]==120 and commands[0][2]==240 and commands[0][4]==70,"authoritative slot position/radius retained")
	slot.warning=.3
	commands = PRIMITIVES.capture(host)
	check(commands.size()==1 and commands[0][0]=="ring" and is_equal_approx(float(commands[0][8]),.5),"warning is outline only")
	slot.mode="lob"; slot.launch=Vector2.ZERO; slot.landing=Vector2(140,240)
	commands = PRIMITIVES.capture(host)
	check(commands.size()==3 and commands[2][1]==140 and commands[2][2]==240,"airborne lob and landing warning both mirrored")
	slot.warning=0.0; slot.mode="orbit"; slot.count=3; slot.phase=.3; slot.orbit_radius=100.0
	commands = PRIMITIVES.capture(host)
	check(commands.size()==6,"all orbit instances mirrored")
	for index in 3:
		var point: Vector2 = host.delivery.orbit_point(slot,index)
		check(Vector2(commands[index*2][1],commands[index*2][2]).is_equal_approx(point),"orbit shares solo point calculation")
	var texture: Texture2D = load("res://assets/art/heroes/stage1_mage/frames/idle_01.png")
	slot.frames=[texture]
	var sampler := SAMPLE.new(); var visuals: Array = []
	sampler.append_weapon_areas(host,visuals)
	check(visuals.size()==3,"orbit PNG instances mirrored")
	for row in visuals: check(ART.valid(row),"PNG command uses existing validated wire")
	slot.warning=.1; visuals.clear(); sampler.append_weapon_areas(host,visuals)
	check(visuals.is_empty(),"warning does not draw active PNG")
	slot.left=0; check(PRIMITIVES.capture(host).is_empty(),"expired slots disappear")
	host.evolution=EVOLUTION.new(); host.evolution.install(host); host.evolution.enabled=true
	var evolved: Dictionary = host.evolution.slots[0]
	evolved.merge({"left":2.0,"kind":"cross","origin":Vector2(30,80),"radius":60.0,"direction":Vector2.RIGHT,"data":{"color":"ffffff"}},true)
	commands=PRIMITIVES.capture(host)
	check(commands.size()==3 and PRIMITIVES.valid(commands),"evolved cross ring and both lines mirrored")
	evolved.kind="awakening_wave"; evolved.phase=0
	commands=PRIMITIVES.capture(host)
	check(commands.size()==1 and is_equal_approx(float(commands[0][4]),36.0),"wave phase shares solo radius")
	evolved.kind="return"; evolved.position=Vector2(55,90); evolved.id="test_return"; host.art.test_return=[texture]
	commands=PRIMITIVES.capture(host); visuals.clear(); sampler.append_weapon_areas(host,visuals)
	check(commands.size()==2 and visuals.size()==1 and commands[0][1]==55 and visuals[0][10]==55,"return projectile PNG and area follow current position")
	evolved.kind="counter"
	check(PRIMITIVES.capture(host).is_empty(),"hidden counter slot remains hidden")
	host.authority=Authority.new(); host.authority.actor.position=Vector2(90,30)
	var mark: Dictionary=host.evolution.marks[0]
	mark.merge({"left":2.0,"count":1,"data":{"awakening_mark_hits":3}},true)
	commands=PRIMITIVES.capture(host)
	check(commands.size()==1 and commands[0][0]=="polyline" and commands[0][10].size()==32 and PRIMITIVES.valid(commands),"partial mark arc mirrored within existing point limit")
	var arc_end:=Vector2(commands[0][10][30],commands[0][10][31])
	check(arc_end.is_equal_approx(Vector2.from_angle(TAU/3)*20),"mark progress is partial arc rather than full ring")
	host.authority.actor.set_meta("hero_detection_hidden",true)
	check(PRIMITIVES.capture(host).is_empty(),"hidden mark targets remain hidden")
	host.authority.actor.free()
	host.hero.free()
	print("ONLINE_DELIVERY_PRESENTATION checks=",checks," failures=",failures)
	quit(1 if failures else 0)
