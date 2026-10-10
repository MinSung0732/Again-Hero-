"""Reverse exact wave receipt caller hooks for legacy comparisons."""
OLD = '\t\tmonster.call("take_damage", damage)\n\t\tif not _is_wave_life_current(life_revision):\n\t\t\treturn\n\n\t\t# Scalar result is fixed before hit-heal callbacks can recycle the victim.\n\t\tvar observation := DAMAGE_OBSERVATION.observe_legacy_hit(\n\t\t\tmonster if is_instance_valid(monster) else null, scope, victim_handle, hp_before\n\t\t)\n\t\tvar killed := DAMAGE_OBSERVATION.is_legacy_kill_candidate(observation)\n'
NEW = '\t\tvar uses_receipt := (\n\t\t\tmonster.has_method("supports_damage_receipt")\n\t\t\tand monster.has_method("take_damage_with_result")\n\t\t\tand bool(monster.call("supports_damage_receipt"))\n\t\t)\n\t\tif not _is_wave_life_current(life_revision):\n\t\t\treturn\n\t\tif not is_instance_valid(monster) or monster.is_queued_for_deletion():\n\t\t\tcontinue\n\t\tif tracked_targets and victim_handle != Vector3i.ZERO and scope.call("resolve_battle_entity", victim_handle) != monster:\n\t\t\tcontinue\n\t\tvar receipt_ready := false\n\t\tvar receipt_revision: int = _wave_damage_receipt.revision + 1\n\t\tif uses_receipt:\n\t\t\treceipt_ready = bool(monster.call("take_damage_with_result", damage, _wave_damage_receipt))\n\t\telse:\n\t\t\tmonster.call("take_damage", damage)\n\t\tif not _is_wave_life_current(life_revision):\n\t\t\treturn\n\n\t\t# Copy the result before hit-heal callbacks can overwrite this shared buffer.\n\t\tvar killed := false\n\t\tif uses_receipt:\n\t\t\tif (\n\t\t\t\treceipt_ready and _wave_damage_receipt.complete\n\t\t\t\tand _wave_damage_receipt.revision == receipt_revision\n\t\t\t\tand _wave_damage_receipt.victim_instance_id == iid\n\t\t\t\tand _wave_damage_receipt.victim_life == victim_handle\n\t\t\t\tand (not tracked_targets or _wave_damage_receipt.identity_verified)\n\t\t\t):\n\t\t\t\tkilled = _wave_damage_receipt.accepted and _wave_damage_receipt.death_started\n\t\telse:\n\t\t\tvar observation := DAMAGE_OBSERVATION.observe_legacy_hit(\n\t\t\t\tmonster if is_instance_valid(monster) else null, scope, victim_handle, hp_before\n\t\t\t)\n\t\t\tkilled = DAMAGE_OBSERVATION.is_legacy_kill_candidate(observation)\n'

def without_wave_receipt(body):
    if body.startswith("func setup("):
        hook = '\tif skill_type == "berserker_wave" and _wave_damage_receipt == null:\n\t\t_wave_damage_receipt = DAMAGE_RECEIPT.new()\n'
        assert body.count(hook) == 1
        body = body.replace(hook, '')
    if body.startswith("func _damage_berserker_wave_sweep("):
        assert body.count(NEW) == 1
        body = body.replace(NEW, OLD)
    return body
