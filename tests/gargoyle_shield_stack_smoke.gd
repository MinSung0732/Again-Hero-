extends SceneTree
## Real Gargoyle/Orc/common hit paths; no full match, asset or mobile simulation.
const G := preload("res://src/monsters/Gargoyle.tscn")
const O := preload("res://src/monsters/orc.gd")
const C := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const RECEIPT := preload("res://src/systems/battle_damage_receipt.gd")
var checks := 0
var failures := 0
class Battle extends Node2D:
 var hero: Node2D
 func fill_monsters_near(point: Vector2, radius: float, out: Array) -> void:
  for child in get_children():
   if child is Node2D and child.is_in_group("monsters") and child.global_position.distance_squared_to(point) <= radius*radius: out.append(child)
class GaugeActor extends Node:
 var gauge := 0.0
class Hero extends Node2D:
 var current_hp := 1000
 var max_hp := 1000
 var shield_hp := 0
 var immune := false
 func take_damage(amount: int, _source: Node = null) -> bool:
  if immune: return false
  current_hp -= amount
  return true
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func make_guard(battle: Node2D, position: Vector2 = Vector2.ZERO):
 var actor = G.instantiate()
 actor.max_hp = 1000
 actor.position = position
 actor.configure_combat_context(battle.hero,battle)
 battle.add_child(actor)
 actor.set_physics_process(false)
 return actor
func run() -> void:
 var battle := Battle.new()
 root.add_child(battle)
 battle.hero = Hero.new()
 battle.add_child(battle.hero)
 var g = make_guard(battle)
 check(CATALOG.get_base_cost("gargoyle") == 14.0,"cost")
 var stats := CATALOG.get_base_stats("gargoyle")
 check(stats.max_hp == 320 and stats.attack_damage == 22,"normalized baseline")
 check(CATALOG.get_elite_skills("gargoyle")[0].cooldown == 10.0,"elite CD")
 check(CATALOG.get_elite_skills("gargoyle")[0].initial_cooldown == 2.0,"elite initial CD")
 check(is_equal_approx(g.ranged_damage_multiplier(),0.6),"full HP ranged reduction")
 HIT.hit(g,100,"ranged",battle.hero)
 check(g.current_hp == 940,"ranged 40% mitigation")
 HIT.hit(g,100,"melee",battle.hero)
 check(g.current_hp == 840,"melee unaffected")
 g.current_hp = 500
 check(is_equal_approx(g.ranged_damage_multiplier(),0.6),"50% boundary")
 g.current_hp = 325
 check(is_equal_approx(g.ranged_damage_multiplier(),0.5),"linear intermediate")
 g.current_hp = 150
 check(is_equal_approx(g.ranged_damage_multiplier(),0.4),"15% max")
 g.current_hp = 80
 check(is_equal_approx(g.ranged_damage_multiplier(),0.4),"low HP clamp")
 g.current_hp = 1000
 C.grant_typed_shield(g,"ranged",150)
 HIT.hit(g,100,"melee",battle.hero)
 check(g.get_meta("ranged_shield_hp") == 150 and g.current_hp == 900,"ranged shield ignores melee")
 HIT.hit(g,100,"ranged",battle.hero)
 check(g.get_meta("ranged_shield_hp") == 90 and g.current_hp == 900,"ranged reduction before shield")
 C.grant_typed_shield(g,"ranged",150)
 C.grant_typed_shield(g,"ranged",150)
 check(g.get_meta("ranged_shield_hp") == 150,"refresh does not stack")
 g.set_meta("ranged_shield_hp",0)
 g.current_hp = 1000
 var ally := O.new()
 var shape := CollisionShape2D.new()
 shape.name = "CollisionShape2D"
 shape.shape = CircleShape2D.new()
 ally.add_child(shape)
 ally.max_hp = 1000
 battle.add_child(ally)
 ally.set_physics_process(false)
 HIT.hit(ally,100,"ranged",battle.hero)
 check(ally.current_hp == 930 and g.current_hp == 982,"30% guarded, guard reduction")
 var second = make_guard(battle,Vector2(150,0))
 HIT.hit(ally,100,"ranged",battle.hero)
 check(ally.current_hp == 860 and g.current_hp == 964 and second.current_hp == 1000,"nearest only, no chain")
 g.position = Vector2(300,0)
 second.position = Vector2(400,0)
 HIT.hit(ally,100,"ranged",battle.hero)
 check(ally.current_hp == 760,"range exclusion")
 g.position = Vector2.ZERO
 second.position = Vector2(500,0)
 HIT.hit(ally,100,"melee",battle.hero)
 check(ally.current_hp == 660,"melee no redirection")
 g.configure_special_augments({"gargoyle_recompense":{}})
 g.current_hp = 1000
 HIT.hit(g,100,"melee",battle.hero)
 check(is_equal_approx(g.stored_damage,30.0),"actual HP loss storage")
 battle.hero.immune = true
 g._attack_target(battle.hero)
 check(is_equal_approx(g.stored_damage,30.0),"no consumption on blocked hit")
 battle.hero.immune = false
 g._attack_target(battle.hero)
 check(g.current_hp == 915 and g.stored_damage == 0.0,"consume storage for 50% heal")
 g.configure_special_augments({"gargoyle_sky_bastion":{}})
 check(g.get_meta("ranged_shield_hp") == 700,"70% current runtime maximum")
 g.set_meta("ranged_shield_hp",0)
 g.configure_special_augments({"gargoyle_stone_slumber":{}})
 g.current_hp = 600
 HIT.hit(g,200,"melee",battle.hero)
 check(g.petrify_used and g.petrify_remaining == 3.0,"threshold petrification")
 for i in range(3): g._physics_process(1.0)
 check(g.current_hp == 580,"missing HP 600 times30% over3s")
 HIT.hit(g,100,"melee",battle.hero)
 check(g.petrify_remaining == 0.0,"once per life")
 g.set_meta("support_shield_hp",0)
 g.set_meta("ranged_shield_hp",0)
 C.add_support_shield(g,100)
 C.grant_typed_shield(g,"melee",100)
 check(C.sync_bar_order(g) == ["shield","melee"],"new melee above generic")
 g.set_meta("support_shield_hp",0)
 g.set_meta("melee_shield_hp",0)
 C.sync_bar_order(g)
 C.grant_typed_shield(g,"melee",100)
 C.add_support_shield(g,100)
 C.grant_typed_shield(g,"ranged",100)
 check(C.sync_bar_order(g) == ["melee","shield","ranged"],"requested three-type stack")
 g.set_meta("support_shield_hp",0)
 check(C.sync_bar_order(g) == ["melee","ranged"],"depleted row removed")
 C.add_support_shield(g,100)
 check(C.sync_bar_order(g) == ["melee","ranged","shield"],"regrant top")
 C.grant_typed_shield(g,"melee",100)
 check(C.sync_bar_order(g) == ["ranged","shield","melee"],"refresh most recent")
 var order := C.sync_bar_order(g)
 check(order == C.sync_bar_order(g),"stable order between redraws")
 check(C.BAR_HEIGHT == 6.0 and C.BAR_GAP == 3.0,"shared row dimensions")
 g.current_hp = 1000
 ally.current_hp = 1000
 ally.set_meta("ranged_shield_hp",0)
 check(g.try_cast_elite_skill({"radius":200.0,"shield_amount":150}),"elite cast")
 check(ally.get_meta("ranged_shield_hp") == 150,"elite nearby ally")
 check(not second.has_meta("ranged_shield_hp"),"elite outside radius")
 g.set_meta("stun_active",true)
 check(not g.try_cast_elite_skill({}),"elite blocked by stun")
 g.remove_meta("stun_active")
 check(not ally.has_meta("incoming_attack_kind") and not g.has_meta("guard_transfer"),"scoped context cleanup")
 # Authoritative receipt measures the local victim, not redirected ally damage.
 g.set_meta("support_shield_hp",0)
 g.set_meta("melee_shield_hp",0)
 g.set_meta("ranged_shield_hp",0)
 g.current_hp = 1000
 var receipt := RECEIPT.new()
 C.grant_typed_shield(g,"ranged",30)
 check(HIT.hit(g,100,"ranged",battle.hero,receipt),"receipt completes")
 check(receipt.requested_damage == 100 and receipt.hp_damage == 30 and receipt.shield_absorbed == 30,"typed shield receipt")
 check(g.current_hp == 970,"receipt actual HP")
 g.set_meta("incoming_attack_kind","previous")
 g.set_meta("_status_damage_source",battle.hero)
 HIT.hit(g,10,"melee",battle.hero)
 check(g.get_meta("incoming_attack_kind") == "previous" and g.get_meta("_status_damage_source") == battle.hero,"nested context restored")
 g.remove_meta("incoming_attack_kind")
 g.remove_meta("_status_damage_source")
 C.grant_typed_shield(g,"melee",50)
 HIT.hit(g,20,"ranged",battle.hero)
 check(g.get_meta("melee_shield_hp") == 50,"melee shield ignores ranged")
 HIT.hit(g,30,"melee",battle.hero)
 check(g.get_meta("melee_shield_hp") == 20,"melee shield absorbs melee")
 C.add_support_shield(g,40)
 HIT.hit(g,50,"melee",battle.hero)
 check(g.get_meta("melee_shield_hp") == 0 and g.get_meta("support_shield_hp") == 10,"typed then universal shield")
 g.current_hp = 1
 g.set_meta("support_shield_hp",0)
 HIT.hit(g,5,"melee",battle.hero,receipt)
 check(receipt.death_started and receipt.hp_damage == 1 and g.dying,"lethal receipt no revive")
 var before_heal: int = g.current_hp
 g._physics_process(5.0)
 check(g.current_hp == before_heal,"no postdeath regeneration")
 check(not g.try_cast_elite_skill({}),"dead caster denied")

 var gauge_actor := GaugeActor.new()
 gauge_actor.gauge = 60.0
 check(C.get_yellow_ratio(gauge_actor,60.0) == 1.0,"Bulgasal60 gauge full")
 gauge_actor.gauge = 75.0
 check(C.get_yellow_ratio(gauge_actor,150.0) == 0.5,"Arthur150 gauge half")
 gauge_actor.free()
 ally.attack_timer = ally.attack_cooldown
 check(C.get_yellow_ratio(ally) == 0.0,"normal attack readiness starts empty")
 ally.attack_timer = 0.0
 check(C.get_yellow_ratio(ally) == 1.0,"normal attack readiness fills")

 print("Gargoyle/shield stack: ",checks," checks, ",failures," failures")
 battle.free()
 quit(1 if failures else 0)
