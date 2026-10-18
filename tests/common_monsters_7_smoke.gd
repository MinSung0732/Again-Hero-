extends SceneTree
const C:=preload("res://src/data/monster_catalog.gd")
const D:=preload("res://src/data/frontier_monster_catalog.gd")
const A:=preload("res://src/data/demon_augment_catalog.gd")
const SHOP:=preload("res://src/data/shop_catalog.gd")
const CONTROL:=preload("res://src/data/hero_control_spawn_catalog.gd")
const IDS:=["cave_ant","thorn_hedgehog","spore_mushroom","shell_crab","swamp_toad","rag_scarecrow","rust_automaton"]
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void: run.call_deferred()
func run()->void:
 check(SHOP.get_monster_pool("common").size()==23,"common collection expands from 16 to 23")
 for id in IDS:
  var data:Dictionary=C.get_monster(id)
  var stats:Dictionary=C.get_base_stats(id)
  check(C.get_rarity(id)=="common",id+" common grade")
  check(id in SHOP.get_monster_pool("common"),id+" same-rarity gacha pool")
  check(C.get_scene(id)!=null,id+" real spawn scene")
  check(stats.max_hp>1 and stats.attack_damage>1,id+" resolved cost budget")
  check(A.get_special_augments_for_monster(id).size()==3,id+" three named augments")
  check(data.elite_skills.size()==1,id+" one elite skill")
  check(D.DEFINITIONS[id].normal_visual.asset_dir!=data.elite_visual.asset_dir,id+" distinct normal/elite art")
  check(D.DEFINITIONS[id].normal_visual.animations.attack.count==6,id+" six attack frames")
 check(CONTROL.is_control(C.get_monster("spore_mushroom"),false),"spore obeys hero CC cap")
 check(CONTROL.is_control(C.get_monster("swamp_toad"),false),"toad obeys hero CC cap")
 print("COMMON_MONSTERS_7 checks=",checks," failures=",failures)
 quit(1 if failures else 0)
