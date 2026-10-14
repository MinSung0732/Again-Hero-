extends SceneTree
const POLICY := preload("res://src/hero_mode/hero_control_policy.gd")
func _initialize() -> void:
	var policy := POLICY.new()
	assert(is_equal_approx(policy.accept(5.0,0.0),2.0))
	for hit in 100:
		assert(policy.accept(1.0,0.0) == 0.0)
	policy.tick(2.0)
	assert(policy.accept(1.0,0.0) == 0.0)
	policy.tick(1.49)
	assert(policy.accept(1.0,0.0) == 0.0)
	policy.tick(0.02)
	assert(is_equal_approx(policy.accept(2.0,0.5),2.0))
	assert(is_equal_approx(policy.remaining,2.5))
	policy.reset()
	assert(policy.accept(0.0,0.0) == 0.0)
	assert(is_equal_approx(policy.accept(1.0,0.0),1.0))
	print("PASS hero control policy")
	quit()
