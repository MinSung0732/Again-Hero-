"""Compare original gameplay bodies against a selected pre-patch Git revision.

After pulling this checkpoint: python3 tests/verify_status_boundary_preservation.py
Use --baseline-ref <pre-patch SHA> when HEAD is beyond this checkpoint.
The four extended adapter bodies are exercised by Godot instead of normalized.
"""
import argparse
import re
import subprocess
from pathlib import Path
from status_receipt_source import normalize_component, normalize_legacy_status

ROOT = Path(__file__).resolve().parents[1]
PATHS = ['src/hero/hero.gd', 'src/monsters/bulgasal.gd',
         'src/hero/archmage_element_status.gd',
         'src/systems/yuki_onna_runtime.gd', 'src/systems/received_afflictions.gd']

def functions(text):
    matches = list(re.finditer(r'^(?:static )?func (\w+)\(', text, re.M))
    return {m.group(1): text[m.start():matches[i+1].start() if i+1 < len(matches) else len(text)].strip()
            for i, m in enumerate(matches)}

def moved_body(original, helper):
    # Keep original signature; undo only the optional receipt observation hook.
    body = helper[helper.index(' -> void:\n')+len(' -> void:\n'):]
    body = re.sub(r'\tif receipt != null:\n\t\treceipt.record_application[^\n]+\n?', '', body)
    return original[:original.index(' -> void:\n')+len(' -> void:\n')] + body

def verify(ref):
    total = 0
    for path in PATHS:
        old = functions(subprocess.check_output(['git', 'show', ref+':'+path], cwd=ROOT).decode())
        new = functions((ROOT/path).read_text())
        count = 0
        for name, original in old.items():
            body = new[name]
            if path.endswith('/hero.gd'):
                body = normalize_legacy_status(body+'\n').strip()
            elif path.endswith('/bulgasal.gd') and name in ['apply_stun', 'apply_silence']:
                body = moved_body(original, new['_'+name+'_status']).strip()
            elif path.endswith('/archmage_element_status.gd') and name in ['apply_burn', 'apply_freeze']:
                body = moved_body(original, new['_apply_element_'+name[6:]]).strip()
            elif path.endswith('/yuki_onna_runtime.gd'):
                body = re.sub(r'^\t(?:status_result_complete = [^\n]+|var receipt_revision: int = [^\n]+|status_receipt.record_application[^\n]+)\n?', '', body, flags=re.M).strip()
            elif path.endswith('/received_afflictions.gd'):
                if name.endswith('_with_result'):
                    continue  # Intentional generic result support; tested dynamically.
                body = normalize_component(body+'\n').strip()
                if name == '_supports_result':
                    body = re.sub(r'^\t#.*\n', '', body, flags=re.M)
                    original = re.sub(r'^\t#.*\n', '', original, flags=re.M)
            assert body == original, (path, name, 'gameplay body changed')
            count += 1
        total += count
        print(path, 'preserved bodies:', count)
    print('Status boundary gameplay preservation PASS:', total)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline-ref', default='HEAD^')
    verify(parser.parse_args().baseline_ref)
