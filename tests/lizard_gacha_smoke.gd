extends SceneTree
const SHOP := preload("res://src/data/shop_catalog.gd")
func _init() -> void:
 var pool := SHOP.get_monster_pool("uncommon")
 assert("lizardman_fighter" in pool)
 assert(SHOP.get_monster_probability("lizardman_fighter") > 0.0)
 var i := pool.find("lizardman_fighter")
 assert(SHOP.roll_monster("uncommon",(i+0.5)/pool.size()) == "lizardman_fighter")
 print("Lizard gacha: 3 checks PASS, uncommon pool ",pool)
 quit()
