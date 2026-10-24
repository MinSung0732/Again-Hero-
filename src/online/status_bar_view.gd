extends Node2D
## Snapshot-driven bar commands; movement changes transforms, not bar geometry.
const PAINTER := preload("res://src/ui/battle_bar_painter.gd")
const HERO_ART := preload("res://src/data/hero_presentation_catalog.gd")

class Bar extends Node2D:
	var wire_id := -1
	var bars: Array = []
	var archetype := ""
	var resource: Dictionary = {}
	var left := 0.0
	var refreshes := 0
	func configure(value: Array, hero_archetype: String) -> void:
		if bars == value and archetype == hero_archetype: return
		# Own the small payload: in-place mutation by a caller must not hide changes.
		bars = value.duplicate()
		archetype = hero_archetype
		if wire_id == 0:
			resource = HERO_ART.get_status_resource(archetype)
			left = -HERO_ART.STATUS_BAR_WIDTH * 0.5 + HERO_ART.get_status_layout(archetype).x
		refreshes += 1
		queue_redraw()
	func _draw() -> void:
		if bars.is_empty(): return
		if wire_id == 0:
			if int(bars[2]) == 1:
				if int(bars[4]) > 0: PAINTER.draw_hero_cells(self,float(bars[5]),int(bars[4]),int(bars[3]),resource["color"])
			else:
				PAINTER.draw_hero_resource(self,left if bool(resource["use_x_offset"]) else -HERO_ART.STATUS_BAR_WIDTH*0.5,float(bars[5]),float(bars[3])/255.0,resource["color"])
			PAINTER.draw_hero_hp(self,left,float(bars[6]),float(bars[0])/255.0)
			if int(bars[1]) > 0: PAINTER.draw_hero_shield(self,left,float(bars[7]),float(bars[1])/255.0)
			return
		var y := float(bars[2])
		var sx := float(bars[3])/100.0
		var sy := float(bars[4])/100.0
		PAINTER.draw_monster_bar(self,y,float(bars[0])/255.0,PAINTER.MONSTER_HP,sx,sy)
		if int(bars[1]) >= 0: PAINTER.draw_monster_bar(self,y+PAINTER.MONSTER_STEP/sy,float(bars[1])/255.0,PAINTER.MONSTER_YELLOW,sx,sy,true)
		for index in range(5,bars.size(),2):
			PAINTER.draw_monster_bar(self,y-PAINTER.MONSTER_STEP/sy*float((index-5)/2+1),float(bars[index+1])/255.0,PAINTER.SHIELD_COLORS[PAINTER.SHIELD_KINDS[int(bars[index])]],sx,sy)

var capacity := 1
var bindings: Dictionary = {}
var pool: Array[Bar] = []
var available: Array[Bar] = []
var seen: Dictionary = {}

func sync_state(state: Dictionary) -> void:
	seen.clear(); seen[0] = true
	for actor in state.actors: seen[int(actor[0])] = true
	# Release before acquiring, so a full roster turnover reuses the same nodes.
	for bar in pool:
		if bar.wire_id >= 0 and not seen.has(bar.wire_id):
			bindings.erase(bar.wire_id)
			bar.wire_id = -1; bar.bars = []; bar.hide()
			available.append(bar)
	var hero := _acquire(0)
	if hero != null: hero.configure(state.hero[5],String(state.hero_archetype))
	for actor in state.actors:
		var bar := _acquire(int(actor[0]))
		if bar != null: bar.configure(actor[6],"")

func _acquire(id: int) -> Bar:
	if bindings.has(id): return bindings[id]
	var bar: Bar
	if not available.is_empty(): bar = available.pop_back()
	elif pool.size() < capacity:
		bar = Bar.new(); pool.append(bar); add_child(bar)
	else: return null
	bar.wire_id = id; bar.show(); bindings[id] = bar
	return bar

func move_actor(id: int, point: Vector2) -> void:
	var bar: Bar = bindings.get(id)
	if bar != null and bar.position != point: bar.position = point
