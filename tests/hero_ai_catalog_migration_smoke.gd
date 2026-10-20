extends SceneTree
## Catalog migration parity: pickup-seek tuning and AI context reason labels
## must reproduce the previous inline formulas/strings exactly.
const PICKUP_SEEK := preload("res://src/data/hero_pickup_seek_catalog.gd")
const AUGMENTS := preload("res://src/data/hero_augment_catalog.gd")
const BUILD_AI := preload("res://src/ai/hero_build_ai.gd")
var checks := 0
var failures := 0


func _initialize() -> void: run.call_deferred()


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("HERO_AI_CATALOG_FAIL " + label)


# Frozen copy of the removed hero.gd implementation (reference only).
static func legacy_heal_desire(hp_ratio: float) -> float:
	if hp_ratio >= 0.60:
		return 0.0
	if hp_ratio >= 0.45:
		return lerpf(0.20, 0.48, (0.60 - hp_ratio) / 0.15)
	if hp_ratio >= 0.30:
		return lerpf(0.62, 0.88, (0.45 - hp_ratio) / 0.15)
	if hp_ratio >= 0.15:
		return lerpf(1.00, 1.18, (0.30 - hp_ratio) / 0.15)
	return 1.30


# Frozen copy of the removed hero_build_ai.gd label match (reference only).
static func legacy_context_label(key: String, value: float) -> String:
	match key:
		"purifier_link_count": return "현재 정화의 구체 연결선 %d개" % int(value)
		"purifier_active_orb_count": return "현재 설치된 정화의 구체 %d개" % int(value)
		"purifier_cleansing_progress_ratio": return "정화 누적 진행 %.0f%%" % (clampf(value, 0.0, 1.0) * 100.0)
		"purifier_cleansing_target_count": return "현재 정화 대상 %d명" % int(value)
		"purifier_crown_stacks": return "용기의 왕관 %d스택" % int(value)
		"purifier_crown_stack_ratio": return "용기의 왕관 누적 %.0f%%" % (clampf(value, 0.0, 1.0) * 100.0)
		"purifier_protection_break_count": return "이번 전투 신성보호 파괴 %d회" % int(value)
		"sage_condensation_ratio": return "마력응축 누적 %.0f%%" % (clampf(value, 0.0, 1.0) * 100.0)
	return "전용 상황 %s %.2f" % [key, value]


func run() -> void:
	# Every 0.001 HP step plus band edges and their float neighbours.
	var samples: Array[float] = []
	for step in 1001: samples.append(float(step) / 1000.0)
	for edge in [0.15, 0.30, 0.45, 0.60]:
		samples.append_array([edge, edge - 0.0000001, edge + 0.0000001])
	var mismatches := 0
	for hp in samples:
		if PICKUP_SEEK.heal_desire_for_hp(hp) != legacy_heal_desire(hp): mismatches += 1
	expect(mismatches == 0, "heal desire curve bit-identical (%d mismatches / %d)" % [mismatches, samples.size()])

	var keys: Array = AUGMENTS.CONTEXT_LABELS.keys()
	keys.append("gunner_reload_state")
	for key in keys:
		for value in [0.0, 0.25, 0.5, 1.0, 1.7, 3.0, 12.9, -2.0]:
			var rule := {"source": "context_linear", "key": key}
			var context := {key: value}
			var actual: String = BUILD_AI._describe_rule(rule, context)
			expect(actual == legacy_context_label(key, value), "%s=%s reason text" % [key, value])
	expect(AUGMENTS.describe_context("unknown_key", 1.0).is_empty(), "unknown key has no catalog label")

	for band in PICKUP_SEEK.HEAL_DESIRE_BANDS:
		expect(band.has("value") or (band.has("hp_max") and float(band.span) > 0.0), "band shape")

	if failures == 0:
		print("HERO_AI_CATALOG_MIGRATION_PASS checks=", checks)
		quit(0)
	else:
		print("HERO_AI_CATALOG_MIGRATION_FAIL failures=", failures, " checks=", checks)
		quit(1)
