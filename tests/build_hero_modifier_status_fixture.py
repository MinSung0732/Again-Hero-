"""Actual modifier/charm application and lifetime slices against the DOT-stage Hero."""
from pathlib import Path
import argparse, re, shutil, subprocess, sys
from status_receipt_source import normalize_legacy_status
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(); p.add_argument('target', type=Path)
base = ['hero', 'control-hero', 'action-scope', 'event-buffer', 'monster-catalog', 'medusa', 'extended-hero', 'burn', 'damage-poison']
for n in base + ['dot-hero', 'succubus']:
    p.add_argument('--' + n + '-baseline', type=Path, required=True)
a = p.parse_args(); out = a.target.resolve()
if out == ROOT or ROOT in out.parents: raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable, str(ROOT / 'tests/build_hero_dot_status_fixture.py'), str(out),
    *[v for n in base for v in ['--' + n + '-baseline', str(getattr(a, n.replace('-', '_') + '_baseline'))]]], check=True)
def fn(s, n):
    m = re.search(r'^func ' + re.escape(n) + r'\(', s, re.M); assert m, n
    tail = s[m.start():]; end = re.search(r'\nfunc ', tail)
    return (tail[:end.start()] if end else tail).rstrip() + '\n\n'
old = a.dot_hero_baseline.read_text(); new = (ROOT / 'src/hero/hero.gd').read_text()
kinds = ['healing_reduction', 'damage_taken_increase', 'charm']
names = re.findall(r'^func ([^(]+)\(', old, re.M)
for n in names:
    body = normalize_legacy_status(fn(new, n))
    if n in ['apply_' + k for k in kinds]:
        body = fn(new, '_apply_' + n[6:] + '_status').replace('_apply_' + n[6:] + '_status', n, 1).replace(', receipt = null, receipt_revision: int = 0', '')
        body = re.sub(r'\tif receipt != null:\n\t\treceipt\.record_application\([^\n]+\)\n', '', body)
    assert body == fn(old, n), n
print('DOT-stage Hero bodies preserved:', len(names))
shutil.copy2(a.succubus_baseline, out / 'src/data/succubus_behavior_catalog.gd')
fields = '''const SUCCUBUS_BEHAVIOR = preload("res://src/data/succubus_behavior_catalog.gd")
var healing_reduction_ratio := 0.0
var healing_reduction_timer := 0.0
var damage_taken_increase_ratio := 0.0
var damage_taken_increase_timer := 0.0
var charm_stacks := 0
var charm_timer := 0.0
var charm_immunity_timer := 0.0
var charm_source: WeakRef
var charm_cooldown_properties: Array = []
var channeling := false
var channel_end_calls := 0
func _get_external_skill_cooldown_properties() -> Array:return [&"test_skill_timer"]
func _end_channel_skill():
\tchannel_end_calls += 1
\tchanneling = false
'''
methods = ['apply_healing_reduction', 'apply_damage_taken_increase', 'apply_charm',
    '_get_reduced_healing', '_tick_received_modifiers', '_clear_received_modifiers',
    'register_succubus_hit', '_tick_charm_timers', '_clear_charm']
for label, s in [('before', old), ('after', new)]:
    path = out / ('src/hero/hero.gd' if label == 'after' else 'tests/hero_status_before.gd')
    # DOT fixture leaves its baseline at the previous stage; these legacy bodies are unchanged.
    extra = [] if label == 'before' else [x for k in kinds for x in ['apply_' + k + '_with_result', '_apply_' + k + '_status']]
    path.write_text(path.read_text() + fields + ''.join(fn(s, n) for n in methods + extra))
with (out / 'tests/hero_status_derived.gd').open('a') as f:
    for k, args in [('healing_reduction', '_duration,_reduction'), ('damage_taken_increase', '_duration,_increase'), ('charm', '_source,_duration')]:
        f.write('func apply_' + k + '(' + args + '):\n\tlegacy_calls += 1\n\treturn true\n')
shutil.copy2(ROOT / 'tests/hero_modifier_status_smoke.gd', out / 'tests/hero_modifier_status_smoke.gd')
