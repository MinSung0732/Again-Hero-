extends RefCounted
## One small token per attack/cast, shared by every hit/projectile/zone it creates.
## No lifetime event registry, per-frame allocation, or changes to raw AI events.
class Token extends RefCounted:
	var counted := false
	var created_at := 0.0

static func current(target: Node) -> RefCounted:
	return target.get_meta("status_action_scope") if is_instance_valid(target) and target.has_meta("status_action_scope") else null

static func action_or_new(target: Node) -> RefCounted:
	var action := current(target)
	return action if action != null else Token.new()

static func begin(target: Node, action: RefCounted) -> RefCounted:
	var previous := current(target)
	if is_instance_valid(target): target.set_meta("status_action_scope",action if action != null else previous)
	return previous

static func finish(target: Node, previous: RefCounted) -> void:
	if is_instance_valid(target): target.set_meta("status_action_scope",previous)
