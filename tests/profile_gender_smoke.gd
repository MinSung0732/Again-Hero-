extends SceneTree
const PROFILE := preload("res://src/systems/player_profile.gd")
const SCOPE := PROFILE.SCOPE
const DIALOG := preload("res://src/ui/profile_gender_dialog.gd")
const VIEW := preload("res://src/ui/lobby_profile_view.gd")
const APPEARANCE := preload("res://src/systems/demon_appearance_store.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
var checks := 0
var failed := false
class Lobby extends Control:
	var other_tab: Control
class Settings extends RefCounted:
	var lobby: Control
	func _title_plate(parent: Control, title: Label) -> PanelContainer:
		var plate := PanelContainer.new(); parent.add_child(plate); plate.add_child(title); return plate
class Cloud extends Node:
	var calls: Array = []
	var fail := false
	var change_owner := false
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		calls.append({"method":method,"data":data.duplicate(true)})
		await get_tree().process_frame
		if change_owner: PROFILE.SCOPE.select_account(preload("res://src/network/cloud_store.gd").new_operation_id())
		if fail: return {"ok":false,"error":"offline"}
		var profile := PROFILE.get_profile()
		profile.gender = data.chosen_gender
		profile.gender_changes_remaining = 0
		return {"ok":true,"profile":profile}
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed = true; push_error(message)
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	await process_frame
	await process_frame
func run() -> void:
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var cloud := Cloud.new(); root.add_child(cloud)
	check(SCOPE.select_account(preload("res://src/network/cloud_store.gd").new_operation_id()),"isolated account")
	var p := {"nickname":"연동마왕","gender":"male","required":false,"completed":true,"nickname_changes_remaining":1,"gender_changes_remaining":1}
	PROFILE._store_response({"ok":true,"profile":p})
	check(PROFILE.can_change_gender(),"independent allowance visible")
	var config := ConfigFile.new(); SCOPE.load_config(config,PROFILE.PATH)
	config.set_value("demon_appearance","equipped_id","original_male")
	config.set_value("profile_cosmetics","avatar_id","original_male")
	SCOPE.save_config(config,PROFILE.PATH)
	var host := Lobby.new(); root.add_child(host); host.other_tab=Control.new(); host.add_child(host.other_tab)
	var settings := Settings.new(); settings.lobby=host
	var view := VIEW.new(); view.install(settings,host.other_tab); view.refresh()
	check(view.gender_button.visible and not view.gender_button.disabled,"profile offers gender action")
	view._open_gender_change()
	check(is_instance_valid(view.gender_dialog),"profile opens actual gender modal")
	view.gender_dialog._close(); await settle()
	check(PROFILE.can_change_gender() and cloud.calls.is_empty(),"cancel spends nothing")
	var dialog := DIALOG.new(); dialog.cloud=cloud; root.add_child(dialog)
	check(dialog.confirm.disabled,"same gender cannot submit")
	dialog._select("female")
	check(not dialog.confirm.disabled and dialog.choices.female.button_pressed,"different gender ready")
	check(dialog.confirm.get_global_rect().size.x>0 and dialog.cancel.get_global_rect().size.y>0,"responsive touch actions exist")
	cloud.fail=true
	await dialog._submit()
	var sent := dialog.operation_id
	check(not sent.is_empty() and PROFILE.get_profile().gender=="male" and PROFILE.can_change_gender(),"failed response preserves local profile/allowance")
	dialog._select("male")
	check(dialog.selected=="female" and dialog.choices.male.disabled,"sent candidate cannot change during retry")
	cloud.fail=false
	var done := [false]; dialog.finished.connect(func():done[0]=true)
	await dialog._submit()
	check(done[0] and cloud.calls.size()==2 and cloud.calls[0].data==cloud.calls[1].data,"retry uses identical gender/UUID")
	check(PROFILE.get_profile().gender=="female" and not PROFILE.can_change_gender() and PROFILE.can_rename(),"gender consumed without rename use")
	check(APPEARANCE.equipped_id("female")=="original_female","old equipped initial appearance falls back to new gender")
	check(COSMETICS.selected_id("avatar")=="original_female" and PROFILE.portrait_path()==PROFILE.PORTRAITS.female,"profile/avatar/dialogue follow new gender")
	view.refresh(); check(not view.gender_button.visible,"used action hidden")
	dialog.queue_free(); host.queue_free(); await settle()
	p.gender_changes_remaining=1
	PROFILE._store_response({"ok":true,"profile":p})
	cloud.change_owner=true
	var result := await PROFILE.change_gender(cloud,"female",sent)
	check(result.get("error")=="account_changed" and PROFILE.get_profile().is_empty(),"late response cannot overwrite another account")
	SCOPE.select_guest()
	check(not PROFILE.can_change_gender(),"guest has no linked allowance")
	cloud.queue_free(); await settle()
	print("PROFILE_GENDER checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
