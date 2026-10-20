extends RefCounted

## Battle-owned node resolution. Online rooms share one SceneTree, so
## tree-wide groups would cross match worlds. Runtime nodes ask their Battle
## parent first; tree groups remain only for isolated scenes/tests without one.
const SCOPED_HERO_METHOD := &"get_scoped_hero"
const SCOPED_GROUP_METHOD := &"fill_scoped_group"
const HERO_GROUP := &"hero"


static func resolve_hero(node: Node) -> Node2D:
	if node == null or not node.is_inside_tree():
		return null
	var authority := node.get_parent()
	if is_instance_valid(authority) and authority.has_method(SCOPED_HERO_METHOD):
		return authority.call(SCOPED_HERO_METHOD) as Node2D
	return node.get_tree().get_first_node_in_group(HERO_GROUP) as Node2D


## Fills `result` in place so callers can keep one reusable Array per group.
static func fill_group(node: Node, group_name: StringName, result: Array) -> void:
	result.clear()
	if node == null or not node.is_inside_tree():
		return
	var authority := node.get_parent()
	if is_instance_valid(authority) and authority.has_method(SCOPED_GROUP_METHOD):
		authority.call(SCOPED_GROUP_METHOD, group_name, result)
		return
	result.assign(node.get_tree().get_nodes_in_group(group_name))
