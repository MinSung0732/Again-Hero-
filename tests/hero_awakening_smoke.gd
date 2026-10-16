extends SceneTree
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
class Arena extends BASE.Arena:
 var active_hero_summons:Dictionary={}
class Ally extends Node2D:
 var owner_hero:Node2D
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
 var empty:Array[Texture2D]=[]
 for row in DATA.WEAPONS.values():RUNTIME.ART.cache[String(row.effect_dir)]=empty
 var arena:=Arena.new();root.add_child(arena)
 var hero:=BASE.Hero.new();hero.position=Vector2(900,1200);arena.add_child(hero)
 hero.damage_poison_tracker=BASE.Clearable.new();hero.burn_runtime=BASE.Clearable.new()
 var target:=BASE.Target.new();target.position=hero.position+Vector2(100,0);arena.add_child(target);arena.targets.append(target)
 var runtime:=RUNTIME.new();runtime.install(hero)
 for id in DATA.WEAPONS:
  var ten:=DATA.GROWTH.resolve(id,DATA.WEAPONS[id],10,false)
  var apex:=DATA.GROWTH.resolve(id,DATA.WEAPONS[id],10,true)
  check(not ten.get("awakening",false) and apex.awakening,id+" MAX exclusive")
  check(is_equal_approx(apex.damage_scale/ten.damage_scale,1.6),id+" 60 percent base damage")
  check(apex.reach_scale>ten.reach_scale*1.29,id+" actual reach increases")
  check(not DATA.GROWTH.evolution_description(id).is_empty(),id+" explained")
 # Wing acquisition must work even when the only free slot is immediately before cursor.
 var id:="swift_hunter_throwing_knife"
 runtime.levels[id]=10;runtime.evolved[id]=true
 var data:=runtime.stats_for(id)
 for shot in runtime.projectiles:shot.active=true
 runtime.projectile_cursor=10;runtime.projectiles[9].active=false
 runtime.evolution.awakening_cast(data,hero.position,Vector2.RIGHT,target,100,600)
 check(runtime.projectiles[9].active and runtime.projectiles[9].flight=="return","last free slot receives returning MAX wing")
 check(Vector2(runtime.projectiles[9].direction).distance_to(Vector2.RIGHT)>.1,"wing is a separate trajectory")
 for shot in runtime.projectiles:shot.active=false
 runtime.levels.pistol_hero_revolver=10;runtime.evolved.pistol_hero_revolver=true
 data=runtime.stats_for("pistol_hero_revolver")
 var index:=runtime._launch_projectile(target,hero.position,100,10,Color.WHITE,data)
 check(runtime.projectiles[index].flight=="bounce" and runtime.projectiles[index].bounces==6,"revolver becomes actual seven-target ricochet")
 runtime.levels.chemical_hero_acid_vial=10;runtime.evolved.chemical_hero_acid_vial=true
 data=runtime.stats_for("chemical_hero_acid_vial")
 runtime.delivery.cast("chemical_hero_acid_vial",data,hero.position,100,600,10,target)
 var landings:Array[Vector2]=[]
 for slot in runtime.delivery.slots:
  if slot.left>0:landings.append(slot.landing)
 check(landings.size()==3 and landings[0].distance_to(landings[1])>150,"MAX bottles land in three separate areas")
 # Knight MAX changes the actual geometry: rear target is hit by the primary nova.
 for shot in runtime.projectiles:shot.active=false
 runtime.levels.sword_shield_hero_longsword=10;runtime.evolved.sword_shield_hero_longsword=true
 target.position=hero.position-Vector2(90,0);var hp:=target.current_hp
 runtime._cast("sword_shield_hero_longsword")
 check(runtime.stats_for("sword_shield_hero_longsword").pattern=="nova" and target.current_hp<hp,"MAX sword hits behind its wielder")
 # Two bounded waves actually hit at different times, without self-proccing.
 for slot in runtime.evolution.slots:slot.left=0
 data=runtime.stats_for("sword_shield_hero_longsword")
 runtime.evolution.awakening_cast(data,hero.position,Vector2.RIGHT,target,100,300)
 hp=target.current_hp;runtime.evolution.tick(.21)
 check(target.current_hp<hp,"first expanding wave deals damage")
 hp=target.current_hp;runtime.evolution.tick(.29)
 check(target.current_hp<hp,"second expanding wave deals damage")
 for slot in runtime.evolution.slots:check(slot.left<=0,"waves finish in bounded slots")
 # Three registered allies fire three rounds each through the real command path.
 for shot in runtime.projectiles:shot.active=false
 for ally_index in 3:
  var ally:=Ally.new();ally.owner_hero=hero;ally.position=hero.position
  arena.add_child(ally);arena.active_hero_summons[ally.get_instance_id()]=ally
 runtime.levels.summoner_hero_gate_hound=10;runtime.evolved.summoner_hero_gate_hound=true
 data=runtime.stats_for("summoner_hero_gate_hound")
 runtime.evolution.on_cast(data,hero.position,Vector2.RIGHT,target,100,600)
 var volleys:=0
 for shot in runtime.projectiles:
  if shot.active:volleys+=1
 check(volleys==9,"three allies launch nine real command rounds")
 for slot in runtime.evolution.slots:slot.left=0
 runtime.levels.ranged_rookie_barrier_book=10;runtime.evolved.ranged_rookie_barrier_book=true
 data=runtime.stats_for("ranged_rookie_barrier_book")
 runtime.evolution.awakening_cast(data,hero.position,Vector2.RIGHT,target,100,300)
 hero.shield_hp=0;runtime.shield_left=0;hp=target.current_hp
 runtime.evolution.tick(.1)
 check(target.current_hp==hp,"shield halo stops when shield is gone")
 arena.queue_free();await process_frame
 print("HERO_AWAKENING checks=",checks," failures=",failures);quit(1 if failures else 0)
