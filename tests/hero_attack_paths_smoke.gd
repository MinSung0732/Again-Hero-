extends SceneTree
const DATA:=preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME:=preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE:=preload("res://tests/hero_weapon_extension_smoke.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func reset(runtime,arena) -> void:
 runtime.resolved.clear();runtime.evolved.clear()
 for shot in runtime.projectiles:shot.active=false
 for slot in runtime.delivery.slots:slot.left=0.0
 for slot in runtime.evolution.slots:slot.left=0.0
 for actor in arena.targets:actor.current_hp=100000;actor.position=Vector2(-9999,-9999)
func active(runtime) -> Dictionary:
 for shot in runtime.projectiles:
  if shot.active:return shot
 return {}
func run() -> void:
 var arena:=BASE.Arena.new();root.add_child(arena)
 var hero:=BASE.Hero.new();arena.add_child(hero);hero.position=Vector2(900,1200)
 hero.damage_poison_tracker=BASE.Clearable.new();hero.burn_runtime=BASE.Clearable.new()
 for index in 3:
  var actor:=BASE.Target.new();arena.add_child(actor);arena.targets.append(actor)
 var runtime:=RUNTIME.new();var empty:Array[Texture2D]=[]
 for row in DATA.WEAPONS.values():RUNTIME.ART.cache[String(row.effect_dir)]=empty
 runtime.install(hero)
 # Straight bullets keep their launch direction rather than following a displaced enemy.
 reset(runtime,arena);var enemy=arena.targets[0];enemy.position=hero.position+Vector2(200,0)
 var id:="pistol_hero_revolver";runtime.levels[id]=1;runtime.magazines[id]=99;runtime._cast(id)
 var shot:=active(runtime);check(shot.flight=="straight","gunner uses physical straight flight")
 enemy.position+=Vector2(0,200);runtime._tick_projectiles(.1)
 check(is_zero_approx(float(shot.position.y)-hero.position.y),"straight bullet never homes to moved target")
 # Piercing crosses two separate actors in order using the same retained shot.
 reset(runtime,arena);enemy.position=hero.position+Vector2(70,0);arena.targets[1].position=hero.position+Vector2(140,0)
 id="ranged_rookie_arcane_bolt";runtime.levels[id]=1;runtime._cast(id)
 for index in 5:runtime._tick_projectiles(.05)
 check(enemy.current_hp<100000 and arena.targets[1].current_hp<100000,"one lance hits front and rear actors")
 # Returning dagger can strike the same actor on each leg, with per-leg victim exclusion.
 reset(runtime,arena);enemy.position=hero.position+Vector2(90,0)
 id="swift_hunter_throwing_knife";runtime.levels[id]=1;runtime._cast(id)
 var hp:int=enemy.current_hp
 for index in 50:runtime._tick_projectiles(.025)
 var raw:=maxi(1,roundi(hero.attack_damage*float(runtime.stats_for(id).power)))
 check(hp-enemy.current_hp>=raw*2,"dagger outbound and return actually hit")
 # A ricochet changes direction only after impact and hits another target.
 reset(runtime,arena);enemy.position=hero.position+Vector2(70,0);arena.targets[1].position=hero.position+Vector2(70,100)
 id="pistol_hero_ricochet";runtime.levels[id]=1;runtime._cast(id)
 for index in 30:runtime._tick_projectiles(.025)
 check(enemy.current_hp<100000 and arena.targets[1].current_hp<100000,"ricochet reaches perpendicular second enemy")
 # Bottle does no damage in flight; impact anchors its later field at the landing point.
 reset(runtime,arena);enemy.position=hero.position+Vector2(160,0)
 id="chemical_hero_acid_vial";runtime.levels[id]=1;runtime._cast(id)
 runtime.delivery.tick(.4);check(enemy.current_hp==100000,"bottle flight has no ground damage")
 runtime.delivery.tick(.4);runtime.delivery.tick(.05)
 check(enemy.current_hp<100000,"bottle lands and damages at target position")
 # Growth remains meaningful at every level; the old budget must not flatten it.
 for weapon in DATA.WEAPONS:
  var base:=DATA.GROWTH.resolve(weapon,DATA.WEAPONS[weapon],1,false)
  var previous_hit:=0.0
  for rank in range(1,11):
   var ranked:=DATA.GROWTH.resolve(weapon,DATA.WEAPONS[weapon],rank,false)
   var hit:float=float(ranked.power)*float(ranked.damage_scale)
   check(hit>previous_hit,"per-hit damage grows every level "+weapon+str(rank))
   previous_hit=hit
  var ten:=DATA.GROWTH.resolve(weapon,DATA.WEAPONS[weapon],10,false)
  var maxed:=DATA.GROWTH.resolve(weapon,DATA.WEAPONS[weapon],10,true)
  check(is_equal_approx(ten.damage_scale,4.6) and is_equal_approx(maxed.damage_scale,7.36),"100 weapon growth factors "+weapon)
  if String(base.pattern) in ["bolt","combo","burst"]:
   var first_dps:=float(base.power)*float(base.damage_scale)*(int(base.get("base_hits",1))+int(base.get("bonus_hits",0)))/(float(base.cooldown)*float(base.cooldown_scale))
   var last_dps:=float(maxed.power)*float(maxed.damage_scale)*mini(6,int(maxed.get("base_hits",1))+int(maxed.get("bonus_hits",0)))/(float(maxed.cooldown)*float(maxed.cooldown_scale))
   check(last_dps>first_dps*3,"MAX direct-weapon output materially exceeds Lv1 "+weapon)
 # Stage3 boss real target HP; stationary no-armour target and no native passive.
 reset(runtime,arena);enemy.position=hero.position+Vector2(150,0)
 enemy.current_hp=15400;enemy.max_hp=15400
 id="ranged_rookie_arcane_bolt";runtime.levels[id]=10;runtime.evolved[id]=true;runtime.resolved.clear();runtime.weapon_ids.clear();runtime.weapon_ids.append(id);runtime.cooldowns[id]=0.0
 var elapsed:=0.0
 while enemy.current_hp>0 and elapsed<300:
  runtime.tick(.05,true);elapsed+=.05
 check(enemy.current_hp<=0 and elapsed<300,"MAX starter beats stationary 15400HP boss within five minutes")
 print("STAGE3_BOSS stationary_no_armour_no_research_seconds=",elapsed)
 arena.queue_free();await process_frame
 print("HERO_ATTACK_PATHS checks=",checks," failures=",failures);quit(1 if failures else 0)
