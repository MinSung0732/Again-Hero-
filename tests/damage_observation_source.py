import re
OLD = '\t\t# Snapshot the result before hit-heal callbacks can recycle the victim.\n\t\tvar killed := hp_before > 0 and not is_instance_valid(monster)\n\t\tif hp_before > 0 and is_instance_valid(monster):\n\t\t\tvar same_victim := not tracked_targets\n\t\t\tif tracked_targets and victim_handle != Vector3i.ZERO:\n\t\t\t\tvar current_handle: Vector3i = scope.call("get_battle_entity_handle", monster)\n\t\t\t\t# Normal death retires the handle; a new nonzero generation is another victim.\n\t\t\t\tsame_victim = current_handle == victim_handle or current_handle == Vector3i.ZERO\n\t\t\tif same_victim:\n\t\t\t\tvar hp_after_value = monster.get("current_hp")\n\t\t\t\tkilled = hp_after_value != null and int(hp_after_value) <= 0\n'
NEW = '\t\t# Scalar result is fixed before hit-heal callbacks can recycle the victim.\n\t\tvar observation := DAMAGE_OBSERVATION.observe_legacy_hit(\n\t\t\tmonster if is_instance_valid(monster) else null, scope, victim_handle, hp_before\n\t\t)\n\t\tvar killed := DAMAGE_OBSERVATION.is_legacy_kill_candidate(observation)\n'

def without_damage_observation(body):
    if body.startswith("func _damage_berserker_wave_sweep("):
        assert body.count(NEW) == 1
        return body.replace(NEW, OLD)
    return body
