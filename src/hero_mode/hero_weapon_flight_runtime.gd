extends RefCounted
## Reuses the 64 existing projectile records and one spatial-query scratch array.
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const RULES := preload("res://src/data/hero_weapon_attack_catalog.gd")
var owner_ref: WeakRef
var query: Array = []
func install(runtime) -> void: owner_ref = weakref(runtime)
func configure(shot: Dictionary) -> void:
 var rule := RULES.spec(String(shot.data.get("weapon_id","")))
 shot.flight = String(shot.data.get("awakening_flight",rule.get("kind","homing")))
 shot.phase = 0; shot.victims.clear(); shot.strikes = 0; shot.start = shot.position
 shot.pierces = int(shot.data.get("awakening_pierces",rule.get("pierce",1))); shot.bounces = int(shot.data.get("awakening_bounces",rule.get("bounces",0)))
 if shot.flight == "fan": shot.direction = Vector2(shot.direction).rotated(-.085 if int(shot.get("serial",0))%2 == 0 else .085)
func handles(shot: Dictionary) -> bool:
 return not bool(shot.melee) and String(shot.flight) not in ["homing","curve"]
func tick(shot: Dictionary,delta: float) -> void:
 var host = owner_ref.get_ref()
 var speed: float = host.MODE.PROJECTILE_SPEED*host.projectile_speed
 var step: float = minf(speed*delta,maxf(0.0,float(shot.reach)-float(shot.traveled)))
 var previous: Vector2 = shot.position
 var turning: bool = shot.flight == "return" and int(shot.phase) == 1
 if turning:
  shot.direction = previous.direction_to(host.hero.global_position)
  step = minf(step,previous.distance_to(host.hero.global_position))
 shot.position = previous+Vector2(shot.direction)*step
 shot.traveled = float(shot.traveled)+step
 # Swept collision prevents fast rounds tunnelling through targets.
 var center: Vector2 = (previous+Vector2(shot.position))*.5
 var hit_radius: float = 12.0*float(shot.data.get("awakening_visual_scale",1.0))
 var radius: float = step*.5+hit_radius
 host.hero._fill_monster_nodes_near(center,radius,query)
 var first: Node2D = null
 var nearest := INF
 for actor in query:
  if not TARGETS.is_detectable(actor): continue
  var handle: Vector3i = host.authority.get_battle_entity_handle(actor)
  if handle == Vector3i.ZERO or shot.victims.has(handle): continue
  var point := Geometry2D.get_closest_point_to_segment(actor.global_position,previous,shot.position)
  if point.distance_squared_to(actor.global_position)>hit_radius*hit_radius: continue
  var distance: float = previous.distance_squared_to(actor.global_position)
  if distance<nearest: nearest=distance;first=actor
 if first != null:
  var handle: Vector3i = host.authority.get_battle_entity_handle(first)
  var impact: Vector2 = first.global_position
  shot.victims[handle]=true;shot.strikes=int(shot.strikes)+1
  host._hit(first,int(shot.damage),"bolt",int(shot.rank),shot.data)
  host._finish_shot(shot,first)
  if shot.flight in ["lance","return","bounce"]:
   shot.traveled = maxf(0.0,float(shot.traveled)-Vector2(shot.position).distance_to(impact))
   shot.position = impact
  if shot.flight == "bounce":
   if int(shot.strikes)>int(shot.bounces): shot.active=false
   else:
    var next := _next(host,impact,shot.victims)
    if next==null:shot.active=false
    else:shot.position=impact;shot.direction=Vector2(shot.position).direction_to(next.global_position)
  elif shot.flight not in ["lance","return"] or int(shot.strikes)>=int(shot.pierces):
   if shot.flight=="return" and int(shot.phase)==0: _turn(shot)
   else:shot.active=false
 if shot.flight=="return" and int(shot.phase)==0 and float(shot.traveled)>=float(shot.reach)*.5:_turn(shot)
 if float(shot.traveled)>=float(shot.reach) or (turning and Vector2(shot.position).distance_squared_to(host.hero.global_position)<16):shot.active=false
func _turn(shot: Dictionary) -> void:
 shot.phase=1;shot.victims.clear();shot.strikes=0
func _next(host,point: Vector2,victims: Dictionary) -> Node2D:
 host.hero._fill_monster_nodes_near(point,220.0,query)
 var selected: Node2D=null
 var best:=220.0*220.0
 for actor in query:
  if not TARGETS.is_detectable(actor) or victims.has(host.authority.get_battle_entity_handle(actor)):continue
  var distance:float=point.distance_squared_to(actor.global_position)
  if distance<best:best=distance;selected=actor
 return selected
