"""Run empty shipping catalog, then temporary existing-art fixtures; restore bytes.

Do not run concurrently with an editor or another catalog-writing task.
Usage: python tests/run_transcendence_smoke.py GODOT [--native]
"""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
catalog = root / 'src/data/monster_catalog.gd'
original = catalog.read_bytes()
native = '--native' in sys.argv
command = [sys.argv[1], '--path', str(root), '--script', 'tests/transcendence_smoke.gd']
command += ['--rendering-method', 'gl_compatibility', '--resolution', '540x960'] if native else ['--headless']

def run(suffix, fixtures=False):
    args = command + ['--']
    if native:
        args += ['--capture']
    if fixtures:
        args += ['--fixtures']
    with (root.parent / ('transcendence_' + suffix + '.log')).open('w', encoding='utf-8') as log:
        result = subprocess.run(args, cwd=root, stdout=log, stderr=subprocess.STDOUT, timeout=90)
    output = (root.parent / ('transcendence_' + suffix + '.log')).read_text(encoding='utf-8')
    if result.returncode or 'ERROR:' in output or 'TRANSCENDENCE: FAILED' in output:
        raise RuntimeError(output[-5000:])
    print(output.splitlines()[-1])

run('empty')
text = original.decode('utf-8')
for monster_id, rarity in [('yuki_onna', 'rare'), ('wolf', 'uncommon')]:
    start = text.index('\t"' + monster_id + '": {')
    end = text.index('\n\t},', start)
    block = text[start:end]
    old = '"rarity":"' + rarity + '"'
    assert old in block
    block = block.replace(old, '"rarity":"transcendent"', 1)
    rules = '\n\t\t"transcendence":{"mode":"any","conditions":[{"metric":"monsters_summoned","amount":2},{"metric":"mana_spent","amount":3}]},'
    block = block.replace('{', '{' + rules, 1)
    text = text[:start] + block + text[end:]
try:
    catalog.write_bytes(text.encode('utf-8'))
    run('fixture', True)
finally:
    catalog.write_bytes(original)
assert catalog.read_bytes() == original
