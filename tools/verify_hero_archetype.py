"""Prove moved archetype functions equal the originals modulo `hero.`/self.

Usage: python tools/verify_hero_archetype.py KEY RUNTIME_PATH CB2D_JSON
Original comes from `git show HEAD:src/hero/hero.gd`.
"""
import json, re, subprocess, sys

KEY, RUNTIME, CB2D = sys.argv[1:4]
TOKEN = re.compile(r'''
    (?P<str>(?:[&^r]?)(?:"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'))
  | (?P<comment>\#[^\n]*)
  | (?P<num>\d[\w.]*(?:[eE][+-]?\d+)?)
  | (?P<ident>[A-Za-z_]\w*)
  | (?P<ws>\s+)
  | (?P<op>.)
''', re.X)


def sig_tokens(s):
    return [(m.lastgroup, m.group()) for m in TOKEN.finditer(s) if m.lastgroup not in ('ws',)]


def split_funcs(text):
    text = text.replace('\r\n', '\n')
    out = {}
    lines = text.split('\n')
    starts = [i for i, l in enumerate(lines) if l.startswith('func ')]
    tops = [i for i, l in enumerate(lines) if l and not l[0].isspace() and not l.startswith('#') and not l.startswith(')')]
    for i in starts:
        nxt = min([t for t in tops if t > i] + [len(lines)])
        end = nxt
        while end > i + 1 and (lines[end - 1].strip() == '' or lines[end - 1].startswith('#')):
            end -= 1
        out[re.match(r'func (\w+)', lines[i]).group(1)] = '\n'.join(lines[i:end])
    return out

orig_text = subprocess.run(['git', 'show', 'HEAD:src/hero/hero.gd'], capture_output=True, encoding='utf-8').stdout
orig = {k: v for k, v in split_funcs(orig_text).items() if KEY in k}
new = split_funcs(open(RUNTIME, encoding='utf-8').read())
new.pop('_init', None)

members = set(json.load(open(CB2D, encoding='utf-8')))
for line in orig_text.replace('\r\n', '\n').split('\n'):
    m = re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?(?:var|const|func|signal|enum|class)\s+(\w+)', line)
    if m:
        members.add(m.group(1))

ok = True
if set(orig) != set(new):
    print('FUNCTION SET MISMATCH', sorted(set(orig) ^ set(new)))
    ok = False
prefixes = 0
for name in sorted(orig):
    if name not in new:
        continue
    a = sig_tokens(orig[name])
    b = sig_tokens(new[name])
    i = j = 0
    good = True
    while i < len(a) and j < len(b):
        if a[i] == b[j]:
            i += 1; j += 1
            continue
        # Allowed: self -> hero
        if a[i] == ('ident', 'self') and b[j] == ('ident', 'hero'):
            i += 1; j += 1; prefixes += 1
            continue
        # Allowed: X -> hero . X  where X is a hero member
        if b[j] == ('ident', 'hero') and j + 2 < len(b) and b[j + 1] == ('op', '.') and b[j + 2] == a[i] and a[i][0] == 'ident' and a[i][1] in members:
            j += 2; prefixes += 1
            continue
        good = False
        print('DIFF in %s: orig %r vs new %r' % (name, a[i:i + 6], b[j:j + 6]))
        break
    if good and (i != len(a) or j != len(b)):
        good = False
        print('LENGTH DIFF in', name)
    ok = ok and good
print('functions compared:', len(orig), 'allowed rewrites:', prefixes, 'RESULT:', 'IDENTICAL' if ok else 'MISMATCH')
sys.exit(0 if ok else 1)
