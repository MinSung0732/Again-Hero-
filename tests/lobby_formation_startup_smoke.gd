extends SceneTree
const POLICY=preload("res://src/systems/dungeon_entry_policy.gd")
var checks:=0
var failures:=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures+=1;push_error(msg)
func _initialize():call_deferred("run")
func run():
	var scripts=[]
	for variant in ["before","after"]:
		var script=load("res://tests/formation_"+variant+".gd")
		if script==null or not script.can_instantiate():quit(1);return
		scripts.append(script)
	var old=scripts[0].new()
	old.TEAM_LOADOUT_STORE.saved=["c","a","b"]
	old.DEMON_SKILL_LOADOUT_STORE.saved=["s3","s1","s2"]
	old.initialize_from_real_ready_slice()
	check(old.team_selected_ids.is_empty() and old.demon_skill_selected_ids.is_empty(),"baseline reproduces empty startup selection")
	check(not POLICY.blocked_reason(old.team_selected_ids,old.demon_skill_selected_ids,false).is_empty(),"baseline rejects existing saved formation")
	old._setup_team_preview();old._setup_demon_skill_preview()
	check(POLICY.blocked_reason(old.team_selected_ids,old.demon_skill_selected_ids,false).is_empty(),"baseline team tab makes entry work")
	old.dispose();old.free()
	for scenario in ["saved","fallback","partial_monsters","partial_skills","locked"]:
		var actor=scripts[1].new()
		actor.TEAM_LOADOUT_STORE.saved=["c","a","b"]
		actor.DEMON_SKILL_LOADOUT_STORE.saved=["s3","s1","s2"]
		if scenario=="fallback":actor.TEAM_LOADOUT_STORE.saved=[];actor.DEMON_SKILL_LOADOUT_STORE.saved=[]
		if scenario=="partial_monsters":actor.TEAM_LOADOUT_STORE.saved=["a","b"]
		if scenario=="partial_skills":actor.DEMON_SKILL_LOADOUT_STORE.saved=["s1","s2"]
		if scenario=="locked":actor.TEAM_LOADOUT_STORE.saved=["transcendent","locked","b","a","c"]
		actor.initialize_from_real_ready_slice()
		check(actor.current_tab=="main","startup stays in main")
		check(actor.TEAM_LOADOUT_STORE.loads==1 and actor.DEMON_SKILL_LOADOUT_STORE.loads==1,"both stores loaded at startup")
		check(actor.MONSTER_COLLECTION_STORE.loads==1,"collection read once")
		check(actor._formation_card_cache.rebuilds==0,"no card rendering at startup")
		check(not actor.team_available_ids.has("transcendent") and not actor.team_available_ids.has("locked"),"existing collection filtering")
		var allowed=scenario not in ["partial_monsters","partial_skills"]
		check(POLICY.blocked_reason(actor.team_selected_ids,actor.demon_skill_selected_ids,false).is_empty()==allowed,"immediate entry gate "+scenario)
		if scenario=="saved":
			check(actor.team_selected_ids==["c","a","b"] and actor.demon_skill_selected_ids==["s3","s1","s2"],"saved order retained before team tab")
			actor._setup_team_preview();actor._setup_demon_skill_preview()
			check(actor.team_selected_ids==["c","a","b"] and actor.demon_skill_selected_ids==["s3","s1","s2"],"later team tab preserves selection")
		actor.dispose();actor.free()
	print("lobby_formation_startup_smoke: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
