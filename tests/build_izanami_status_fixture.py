"""Actual Izanami caller + actual Hero status slices; no combat scene substitutes."""
from pathlib import Path
import argparse, re, shutil, subprocess, sys
ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(); p.add_argument('target', type=Path)
base = ['hero', 'control-hero', 'extended-hero', 'dot-hero', 'action-scope', 'event-buffer', 'monster-catalog', 'medusa', 'burn', 'damage-poison', 'succubus']
for n in base + ['izanami']:
    p.add_argument('--' + n + '-baseline', type=Path, required=True)
a = p.parse_args(); out = a.target.resolve()
if out == ROOT or ROOT in out.parents: raise SystemExit('Use temporary fixture outside checkout')
subprocess.run([sys.executable, str(ROOT / 'tests/build_hero_modifier_status_fixture.py'), str(out),
    *[v for n in base for v in ['--' + n + '-baseline', str(getattr(a, n.replace('-', '_') + '_baseline'))]]], check=True)
def fn(s, n):
    m = re.search(r'^func ' + re.escape(n) + r'\(', s, re.M); assert m, n
    tail = s[m.start():]; end = re.search(r'\nfunc ', tail)
    return (tail[:end.start()] if end else tail).rstrip() + '\n\n'
old = a.izanami_baseline.read_text(); new = (ROOT / 'src/monsters/izanami.gd').read_text()
names = re.findall(r'^func ([^(]+)\(', old, re.M)
for n in names:
    body = fn(new, n)
    if n == '_status':
        body = body.replace('\tstatus_result_complete = false\n', '')
        body = body.replace('\tstatus_result_complete = _apply_hero_status(kind,strength,seconds)\n',
            '\tmatch kind:\n\t\t"slow": hero.apply_slow(strength,seconds)\n\t\t"stun": hero.apply_stun(seconds)\n\t\t"silence": hero.apply_silence(seconds)\n\t\t"vulnerability": hero.apply_damage_taken_increase(seconds,strength)\n')
    assert body == fn(old, n), n
print('Izanami original bodies preserved:', len(names))
fields = '''extends Node2D
const STATUS_SCOPE = preload("res://src/systems/status_action_scope.gd")
var hero: Node2D
var status_depth := 0
var passive_statuses := 0
'''
for label, s in [('before', old), ('after', new)]:
    extra = '' if label == 'before' else '''const STATUS_RECEIPT = preload("res://src/systems/battle_status_receipt.gd")
var status_receipt = STATUS_RECEIPT.new()
var status_result_complete := false
'''
    methods = ['_status', '_count_own_status'] + ([] if label == 'before' else ['_apply_hero_status'])
    (out / ('tests/izanami_status_' + label + '.gd')).write_text(fields + extra + ''.join(fn(s, n) for n in methods))
# Genuine legacy-only capability fallback: remove only new entry points from the baseline slice.
s = (out / 'tests/hero_status_before.gd').read_text()
for n in ['apply_slow_with_result', 'apply_stun_with_result', 'apply_silence_with_result']:
    s = s.replace(fn(s, n), '')
(out / 'tests/hero_status_legacy_only.gd').write_text(s)
shutil.copy2(ROOT / 'tests/izanami_status_receipt_smoke.gd', out / 'tests/izanami_status_receipt_smoke.gd')
