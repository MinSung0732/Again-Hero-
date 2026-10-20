"""Move hero.gd functions whose name contains KEY into an archetype runtime.

Usage: python tools/extract_hero_archetype.py KEY RUNTIME_PATH CONST_NAME ACCESSOR CB2D_JSON [--write]
CB2D_JSON comes from tools/dump_body_members.gd. Dry run first; then prove
the result with tools/verify_hero_archetype.py before committing.

Moved bodies are verbatim except hero members get a `hero.` prefix and
`self` becomes `hero`. hero.gd keeps a same-signature forwarder per function
so method-name bindings, Callables and tests keep working.
"""
import json, re, sys

KEY, RUNTIME_PATH, CONST_NAME, ACCESSOR, CB2D_JSON = sys.argv[1:6]
WRITE = '--write' in sys.argv
HERO = 'src/hero/hero.gd'

raw = open(HERO, encoding='utf-8', newline='').read()
CRLF = '\r\n' in raw
text = raw.replace('\r\n', '\n')
lines = text.split('\n')

KEYWORDS = set('''if elif else for while match break continue pass return class class_name
extends is in as self signal func static const enum var breakpoint preload await yield
assert void PI TAU INF NAN true false null and or not super when'''.split())

# ---------------------------------------------------------------- tokenizer
TOKEN = re.compile(r'''
    (?P<str>(?:[&^r]?)(?:"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'))
  | (?P<comment>\#[^\n]*)
  | (?P<num>\d[\w.]*(?:[eE][+-]?\d+)?)
  | (?P<ident>[A-Za-z_]\w*)
  | (?P<ws>[ \t]+)
  | (?P<nl>\n)
  | (?P<op>.)
''', re.X)


def tokens(s):
    return [(m.lastgroup, m.group()) for m in TOKEN.finditer(s)]


# -------------------------------------------------------- top-level layout
def is_top(line):
    return bool(line) and not line[0].isspace() and not line.startswith('#') and not line.startswith(')')

tops = [i for i, l in enumerate(lines) if is_top(l)]
members = set(json.load(open(CB2D_JSON, encoding='utf-8')))
DECL = re.compile(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?(var|const|func|signal|enum|class)\s+(\w+)')
enum_values = set()
for i in tops:
    m = DECL.match(lines[i])
    if m:
        members.add(m.group(2))
        if m.group(1) == 'enum':
            body = lines[i][lines[i].find('{') + 1:lines[i].find('}')]
            enum_values.update(re.findall(r'(\w+)\s*(?:=|,|$)', body))
members |= enum_values
inner_classes = {DECL.match(lines[i]).group(2) for i in tops if DECL.match(lines[i]) and DECL.match(lines[i]).group(1) == 'class'}

moved = []  # (name, start, end_exclusive)
for k, i in enumerate(tops):
    m = re.match(r'func (\w+)', lines[i])
    if not m or KEY not in m.group(1):
        continue
    nxt = tops[k + 1] if k + 1 < len(tops) else len(lines)
    end = nxt
    # Leading comments/blank lines before the next declaration stay with it.
    while end > i + 1 and (lines[end - 1].strip() == '' or lines[end - 1].startswith('#')):
        end -= 1
    moved.append((m.group(1), i, end))
moved_names = {n for n, _, _ in moved}

problems = []
out_funcs = []
forwarders = {}
prefixed = 0
for name, a, b in moved:
    body = '\n'.join(lines[a:b])
    toks = tokens(body)
    # Signature span: tokens up to the ':' that closes the header at depth 0.
    depth = 0
    sig_end = None
    for idx, (kind, val) in enumerate(toks):
        if kind == 'op' and val in '([{':
            depth += 1
        elif kind == 'op' and val in ')]}':
            depth -= 1
        elif kind == 'op' and val == ':' and depth == 0 and idx > 2:
            # skip the ':' of '-> Type:' only when it ends the header line
            rest = ''.join(v for _, v in toks[idx + 1:idx + 3])
            if rest.startswith('\n') or rest.strip() == '' or toks[idx + 1][0] in ('nl', 'comment', 'ws'):
                sig_end = idx
                break
    if sig_end is None:
        problems.append(name + ': header not found')
        continue
    header = ''.join(v for _, v in toks[:sig_end + 1])
    params = []
    pdepth = 0
    expect_name = False
    for kind, val in toks[:sig_end]:
        if kind == 'op' and val == '(':
            pdepth += 1
            expect_name = pdepth == 1
            continue
        if kind == 'op' and val == ')':
            pdepth -= 1
            continue
        if pdepth == 1 and kind == 'op' and val == ',':
            expect_name = True
            continue
        if pdepth == 1 and expect_name and kind == 'ident':
            params.append(val)
            expect_name = False
    locals_ = set(params)
    for kind_val in re.finditer(r'\b(?:var|const)\s+(\w+)|\bfor\s+(\w+)\s+in\b', body):
        locals_.add(kind_val.group(1) or kind_val.group(2))
    for lam in re.finditer(r'\bfunc\s*\w*\s*\(([^)]*)\)', body[len(header):]):
        locals_.update(re.findall(r'(\w+)\s*(?::|=|,|$)', lam.group(1)))
    shadow = sorted((locals_ & members) - set())
    if shadow:
        problems.append('%s: locals shadow hero members %s' % (name, shadow))
    # Rewrite body tokens after the header.
    new = [v for _, v in toks[:sig_end + 1]]
    prev_sig = None
    for kind, val in toks[sig_end + 1:]:
        if kind == 'ident':
            if val == 'self':
                val = 'hero'
                prefixed += 1
            elif prev_sig != '.' and val not in KEYWORDS and val not in locals_ and val not in moved_names and val in members:
                if val in inner_classes:
                    problems.append('%s: inner class %s' % (name, val))
                val = 'hero.' + val
                prefixed += 1
        if kind == 'op' and val == '$':
            problems.append(name + ': $ node path')
        new.append(val)
        if kind not in ('ws', 'nl', 'comment'):
            prev_sig = val if kind == 'op' else kind
    # Header: rewrite default-value expressions that reference hero members.
    header_new = []
    prev_sig = None
    after_name = False
    for kind, val in toks[:sig_end + 1]:
        if kind == 'ident' and after_name and prev_sig != '.' and val not in KEYWORDS and val not in params and val in members and prev_sig in ('=', '('):
            problems.append('%s: header default references member %s' % (name, val))
        if kind == 'ident' and val == name:
            after_name = True
        header_new.append(val)
        if kind not in ('ws', 'nl', 'comment'):
            prev_sig = val if kind == 'op' else kind
    out_funcs.append(''.join(new).rstrip('\n'))
    returns_void = re.search(r'->\s*void\s*:\s*$', header) is not None
    call = '%s().%s(%s)' % (ACCESSOR, name, ', '.join(params))
    forwarders[name] = header + '\n\t' + ('' if returns_void else 'return ') + call

print('moved functions:', len(moved), 'lines:', sum(b - a for _, a, b in moved), 'prefixed refs:', prefixed)
for p in problems:
    print('PROBLEM', p)
if not WRITE:
    sys.exit(0 if not problems else 1)
if problems:
    sys.exit('refusing to write with problems')

runtime = '''extends RefCounted
## %s archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


''' % KEY.capitalize() + '\n\n\n'.join(out_funcs) + '\n'
open(RUNTIME_PATH, 'w', encoding='utf-8', newline='').write(runtime)

# Replace moved ranges bottom-up with forwarders.
for name, a, b in sorted(moved, key=lambda t: -t[1]):
    lines[a:b] = forwarders[name].split('\n')
text2 = '\n'.join(lines)
anchor = 'const HERO_SUMMONER_RUNTIME := preload("res://src/hero/hero_summoner_runtime.gd")\n'
assert text2.count(anchor) == 1
res_path = 'res://' + RUNTIME_PATH.replace('\\', '/')
text2 = text2.replace(anchor, anchor + 'const %s := preload("%s")\n' % (CONST_NAME, res_path))
var_name = '_' + KEY + '_archetype_runtime'
accessor = '''

func %s():
	if %s == null:
		%s = %s.new(self)
	return %s
''' % (ACCESSOR, var_name, var_name, CONST_NAME, var_name)
var_anchor = 'var _hero_action_tick: Callable\n'
assert text2.count(var_anchor) == 1
text2 = text2.replace(var_anchor, 'var %s: RefCounted\n' % var_name + var_anchor)
text2 = text2.rstrip('\n') + '\n' + accessor
open(HERO, 'w', encoding='utf-8', newline='').write(text2.replace('\n', '\r\n') if CRLF else text2)
print('written', RUNTIME_PATH)
