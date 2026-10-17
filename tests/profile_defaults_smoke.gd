extends SceneTree
const PROFILE := preload("res://src/systems/player_profile.gd")
const DATA := preload("res://src/data/player_profile_catalog.gd")
const GENDERS := preload("res://src/data/profile_gender_catalog.gd")
const ART := preload("res://src/data/demon_appearance_catalog.gd")
const PROLOGUE := preload("res://src/ui/player_prologue.gd")
const LINES := preload("res://src/data/prologue_catalog.gd")
const SCOPE := PROFILE.SCOPE
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed=true; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(load("res://src/ui/lobby_settings_view.gd")!=null,"real account label consumer parses after autoload setup")
	var initial := DATA.initial_profile()
	check(initial=={"nickname":"","gender":"male","required":true,"completed":false},"preview defaults keep old shape and values")
	initial.gender="female"
	check(DATA.initial_profile().gender=="male","fresh defaults never share mutable state")
	var legacy := {"nickname":"왕","gender":"female","completed":false,"nickname_changes_remaining":1,"gender_changes_remaining":1,"future":{"revision":8}}
	var guest := DATA.guest_profile(legacy)
	check(guest.nickname=="왕" and guest.gender=="female" and guest.future.revision==8 and not guest.required and guest.completed,"guest flags retain legacy identity/extra fields")
	check(guest.nickname_changes_remaining==0 and guest.gender_changes_remaining==0 and legacy.gender_changes_remaining==1,"guest receives no account allowance and caller unchanged")
	guest.future.revision=10
	check(legacy.future.revision==8,"guest copy preserves nested isolation")
	check(DATA.gender_id({})=="male" and DATA.gender_id({"gender":"invalid"})=="invalid","only missing gender receives default")
	check(not GENDERS.valid("invalid") and GENDERS.label("invalid")=="남성","invalid response remains invalid while display fallback stays old male label")
	check(ART.base_portrait("invalid")==ART.base_portrait(GENDERS.DEFAULT_ID),"unknown appearance falls back consistently")
	var id := preload("res://src/network/cloud_store.gd").new_operation_id()
	check(SCOPE.select_account(id),"isolated account")
	SCOPE.write_allowed=Callable(); SCOPE.saved_callback=Callable()
	check(SCOPE.install({"stage_progress.cfg":{"meta":{"gold":777,"research_points":123}}},1),"seed old wallet")
	for gender in GENDERS.OPTIONS:
		var profile := DATA.initial_profile("왕",gender)
		profile.required=false; profile.completed=true
		profile["nickname_changes_remaining"]=1; profile["gender_changes_remaining"]=1
		profile["future"]={"kept":true}
		check(PROFILE._store_response({"ok":true,"profile":profile}).get("ok")==true,"legacy one-character profile still readable: "+gender)
		check(PROFILE.gender_id()==gender and PROFILE.appearance_id()==ART.DEFAULTS[gender],"saved gender drives appearance: "+gender)
		check(PROFILE.portrait_path()==PROFILE.PORTRAITS[gender] and ART.base_portrait(gender).resource_path==PROFILE.PORTRAITS[gender],"base/profile/preloaded portrait share path: "+gender)
		check(PROFILE.appearance_resource_paths().has(PROFILE.PORTRAITS[gender]),"warmup paths include portrait: "+gender)
		var serial := SCOPE.serial
		PROFILE.appearance_id(); PROFILE.portrait_path(); PROFILE.appearance_resource_paths()
		check(SCOPE.serial==serial and PROFILE.get_profile()==profile,"display lookups never mutate profile or revision")
		var view := PROLOGUE.new(); root.add_child(view)
		view.nickname=""
		for i in LINES.LINES.size():
			if LINES.LINES[i].get("kind","")=="gender": view.index=i; break
		view._show_line()
		var button: Button
		for child in view.choice.get_children():
			if child is Button and child.text==GENDERS.label(gender): button=child
		check(button!=null and button.anchor_left==GENDERS.PROLOGUE_CHOICE_RECTS[gender].position.x,"catalog choice keeps label/position: "+gender)
		button.pressed.emit()
		check(view.gender==gender and view.portrait.texture==ART.base_portrait(gender),"actual gender button reveals correct art: "+gender)
		view.queue_free(); await process_frame
	var before := PROFILE.get_profile()
	var invalid := before.duplicate(true); invalid.gender="invalid"
	check(PROFILE._store_response({"ok":true,"profile":invalid}).get("error")=="invalid_response" and PROFILE.get_profile()==before,"invalid server gender is rejected without rewriting existing profile")
	var config := ConfigFile.new(); SCOPE.load_config(config,PROFILE.PATH)
	check(config.get_value("meta","gold",0)==777 and config.get_value("meta","research_points",0)==123,"profile refactor preserves wallet")
	SCOPE.select_account(id)
	check(PROFILE.get_profile()==JSON.parse_string(JSON.stringify(before)) and PROFILE.can_rename() and PROFILE.can_change_gender(),"cache restart retains identity/unknown fields/independent allowances")
	SCOPE.select_guest()
	print("PROFILE_DEFAULTS checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
