extends SceneTree
func _init():
	for name in ["hero_projectile","gunner_projectile","sage_projectile","ultimate_piercing_projectile","summoner_gatekeeper_projectile","archmage_projectile","archmage_skill_projectile"]:
		var script = load("res://src/hero/"+name+".gd")
		if script == null or not script.can_instantiate(): quit(1); return
	print("CX_PROJECTILES compile7 PASS")
	quit()
