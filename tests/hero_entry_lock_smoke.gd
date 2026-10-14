extends SceneTree
const VIEW := preload("res://src/ui/lobby_main_modes_view.gd")
class Host extends Control:
	var enter_stage_button := Button.new()
	var portrait_texture := TextureRect.new()
	var portrait_badge := Label.new()
	var stage_status_label := Label.new()
func _initialize() -> void:
	var host := Host.new()
	root.add_child(host)
	for child in [host.enter_stage_button,host.portrait_texture,host.portrait_badge,host.stage_status_label]: host.add_child(child)
	var lock := Control.new()
	lock.name = "StageLock"
	host.portrait_texture.add_child(lock)
	var view := VIEW.new()
	view.lobby = host
	view.difficulty = "easy"
	for stage in range(2,11):
		view._set_hero_entry_lock(false,stage,false)
		assert(host.enter_stage_button.disabled)
		assert(host.enter_stage_button.text == "Stage %d 클리어 필요" % (stage-1))
		assert(host.portrait_badge.visible and lock.visible)
		assert(host.portrait_texture.self_modulate != Color.WHITE)
	view.difficulty = "hard"
	view._set_hero_entry_lock(false,3,true)
	assert(host.enter_stage_button.text == "Stage 3 클리어 필요")
	host.enter_stage_button.text = "용사 도전 · 15분 생존"
	view._set_hero_entry_lock(true,3,true)
	assert(not host.enter_stage_button.disabled)
	assert(host.enter_stage_button.text == "용사 도전 · 15분 생존")
	assert(not host.portrait_badge.visible and not lock.visible)
	assert(host.portrait_texture.self_modulate == Color.WHITE)
	print("PASS hero entry lock / restore")
	host.free()
	quit()
