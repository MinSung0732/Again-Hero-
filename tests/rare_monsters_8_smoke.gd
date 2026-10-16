extends SceneTree
const C:=preload("res://src/data/monster_catalog.gd")
const D:=preload("res://src/data/frontier_monster_catalog.gd")
const A:=preload("res://src/data/demon_augment_catalog.gd")
const SHOP:=preload("res://src/data/shop_catalog.gd")
const CONTROL:=preload("res://src/data/hero_control_spawn_catalog.gd")
const IDS:=["crystal_tortoise", "ember_salamander", "frost_owl", "thorn_dryad", "dusk_panther", "rune_sentinel", "venom_scorpion", "moon_moth"]
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
 check(SHOP.get_monster_pool("rare").size()==15,"rare roster ends at exactly15")
 check(SHOP.get_monster_pool("common").size()==23,"common roster remains23")
 check(SHOP.get_monster_pool("uncommon").size()==16,"uncommon roster remains16")
 check(CONTROL.is_control(C.get_monster("frost_owl"),false),"frost owl respects control supply")
 check(CONTROL.is_control(C.get_monster("thorn_dryad"),false),"dryad respects control supply")
 check(not CONTROL.is_control(C.get_monster("crystal_tortoise"),false),"normal tortoise has no control")
 check(CONTROL.is_control(C.get_monster("crystal_tortoise"),true),"tortoise elite slow respects control supply")
 for id in IDS:
  var data:Dictionary=C.get_monster(id)
  var stats:Dictionary=C.get_base_stats(id)
  check(C.get_rarity(id)=="rare",id+" rare grade")
  check(id in SHOP.get_monster_pool("rare"),id+" existing gacha route")
  check(C.get_scene(id)!=null,id+" real spawn scene")
  check(stats.max_hp>1 and stats.attack_damage>1,id+" final cost budget")
  check(A.get_special_augments_for_monster(id).size()==3,id+" three named special augments")
  check(data.elite_skills.size()==2,id+" two elite skills")
  check(D.DEFINITIONS[id].normal_visual.asset_dir!=data.elite_visual.asset_dir,id+" two distinct art forms")
  for form in ["normal_visual","elite_visual"]:
   var total:=0
   for config in D.DEFINITIONS[id][form].animations.values():total+=int(config.count)
   check(total==23,id+" 23 real frames "+form)
 print("RARE_MONSTERS_8 checks=",checks," failures=",failures)
 quit(1 if failures else 0)
