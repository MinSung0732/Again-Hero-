extends RefCounted
## Cache the authority per node; a changed parent invalidates the cached scope.
const SCOPE_KEY := &"_battle_clock_scope"
const PARENT_KEY := &"_battle_clock_parent"

static func battle_for(node: Node) -> Node:
	if not is_instance_valid(node) or not node.is_inside_tree(): return null
	var parent := node.get_parent()
	if node.has_meta(PARENT_KEY) and node.get_meta(PARENT_KEY) == parent:
		var cached = node.get_meta(SCOPE_KEY, null)
		if cached == null or is_instance_valid(cached): return cached
	var scope := node
	while is_instance_valid(scope) and not scope.has_method("combat_delta"):
		scope = scope.get_parent()
	node.set_meta(PARENT_KEY, parent)
	node.set_meta(SCOPE_KEY, scope)
	node.tree_exiting.connect(_clear_cache.bind(node), CONNECT_ONE_SHOT)
	return scope

static func _clear_cache(node: Node) -> void:
	if not is_instance_valid(node): return
	node.remove_meta(PARENT_KEY)
	node.remove_meta(SCOPE_KEY)

static func scaled(node: Node, delta: float) -> float:
	var battle := battle_for(node)
	return battle.combat_delta(delta) if battle != null else delta

static func move_and_slide_scaled(body: CharacterBody2D) -> bool:
	var battle := battle_for(body)
	if battle == null: return body.move_and_slide()
	var scale: float = 0.0 if battle.external_pause else battle.clock_scale
	if scale == 1.0: return body.move_and_slide()
	if scale == 0.0: return false
	var original := body.velocity
	body.velocity *= scale
	var collided := body.move_and_slide()
	body.velocity = original
	return collided
