"""Audit current receiver coverage and print direct/dynamic legacy call sites.

Run from any directory. This is a source inventory, not proof that every skill
was exercised, nor an online synchronization/network serialization test.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    'src/hero/hero.gd': {
        'slow', 'stun', 'silence', 'fear', 'paralysis', 'petrify', 'poison',
        'damage_poison', 'bleed', 'burn', 'charm', 'healing_reduction',
        'damage_taken_increase'},
    'src/systems/received_afflictions.gd': {
        'slow', 'stun', 'silence', 'poison', 'bleed_current', 'burn'},
    'src/monsters/bulgasal.gd': {'stun', 'silence'},
    'src/hero/archmage_element_status.gd': {'burn', 'freeze'},
}
KINDS = set().union(*EXPECTED.values())
STATUS = '(?:' + '|'.join(sorted(KINDS)) + ')'
DEFINITION = re.compile(r'^(?:static )?func apply_(' + STATUS + r')\(', re.M)
DIRECT = re.compile(r'\.apply_(' + STATUS + r')\(')
DYNAMIC = re.compile(r'\.call\("apply_(' + STATUS + r')"')

def audit():
    found = {}
    callers = []
    for file in sorted((ROOT / 'src').rglob('*.gd')):
        text = file.read_text()
        path = file.relative_to(ROOT).as_posix()
        matches = list(DEFINITION.finditer(text))
        if matches:
            found[path] = {m.group(1) for m in matches}
            for m in matches:
                end = re.search(r'\n(?:static )?func ', text[m.end():])
                body = text[m.start():m.end()+end.start() if end else len(text)]
                assert 'receipt.begin(' in body, (path, m.group(1), 'missing begin')
                assert 'receipt.finish(' in body, (path, m.group(1), 'missing finish')
        for number, line in enumerate(text.splitlines(), 1):
            if DIRECT.search(line) or DYNAMIC.search(line):
                callers.append((path, number, line.strip()))
    assert found == EXPECTED, ('Receiver inventory changed: review coverage', found)
    yuki = (ROOT / 'src/systems/yuki_onna_runtime.gd').read_text()
    assert 'status_receipt.begin(target,&"yuki_slow"' in yuki
    assert 'status_result_complete = status_receipt.finish(receipt_revision)' in yuki
    assert 'func reset() -> void:\n\tstatus_result_complete = false' in yuki
    print('Status boundary audit PASS: 23 legacy receivers + Yuki custom slow')
    print(f'Direct/dynamic call lines: {len(callers)}; files: {len({x[0] for x in callers})}')
    for path, number, line in callers:
        print(f'{path}:{number}: {line}')

if __name__ == '__main__':
    audit()
