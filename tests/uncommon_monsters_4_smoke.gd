extends SceneTree
const C:=preload("res://src/data/monster_catalog.gd")
const D:=preload("res://src/data/frontier_monster_catalog.gd")
const A:=preload("res://src/data/demon_augment_catalog.gd")
const SHOP:=preload("res://src/data/shop_catalog.gd")
const IDS:=["iron_beetle","lantern_wisp","blade_mantis","moss_deer"]
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
 check(SHOP.get_monster_pool("uncommon").size()==16,"uncommon roster ends at exactly16")
 check(SHOP.get_monster_pool("common").size()==23,"common roster remains23")
 for id in IDS:
  var data:Dictionary=C.get_monster(id)
  var stats:Dictionary=C.get_base_stats(id)
  check(C.get_rarity(id)=="uncommon",id+" uncommon grade")
  check(id in SHOP.get_monster_pool("uncommon"),id+" existing gacha route")
  check(C.get_scene(id)!=null,id+" real spawn scene")
  check(stats.max_hp>1 and stats.attack_damage>1,id+" final cost budget")
  check(A.get_special_augments_for_monster(id).size()==3,id+" three named special augments")
  check(data.elite_skills.size()==1,id+" one elite skill")
  check(D.DEFINITIONS[id].normal_visual.asset_dir!=data.elite_visual.asset_dir,id+" two distinct art forms")
  for form in ["normal_visual","elite_visual"]:
   var total:=0
   for config in D.DEFINITIONS[id][form].animations.values():total+=int(config.count)
   check(total==23,id+" 23 real frames "+form)
 print("UNCOMMON_MONSTERS_4 checks=",checks," failures=",failures)
 quit(1 if failures else 0)
