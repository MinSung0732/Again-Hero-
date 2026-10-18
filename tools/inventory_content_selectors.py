"""List narrow runtime ID comparisons as review candidates, not required removals."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess

SELECTORS = re.compile(
    r'\b(hero_archetype|hero_id|source_hero_id|monster_type|monster_id|stage_id|current_stage_id)'
    r'\s*(==|!=)\s*"([^"\n]+)"'
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    paths = subprocess.check_output(['git', 'ls-files', 'src'], cwd=repo, text=True).splitlines()
    rows = []
    files = 0
    for path in paths:
        if not path.endswith('.gd') or path.startswith('src/data/'):
            continue
        files += 1
        function = '<top-level>'
        for line_no, line in enumerate((repo / path).read_text().splitlines(), 1):
            declaration = re.match(r'^(?:static )?func (\w+)\(', line)
            if declaration:
                function = declaration.group(1)
            if line.lstrip().startswith('#'):
                continue
            for match in SELECTORS.finditer(line):
                rows.append({'path': path, 'line': line_no, 'function': function,
                             'selector': match.group(1), 'operator': match.group(2),
                             'literal': match.group(3)})
    report = {
        'base_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip(),
        'source': 'working tree', 'runtime_scripts_scanned': files,
        'scope': 'Tracked src GDScript excluding src/data; seven named selectors, nonempty '
                 'double-quoted ==/!= comparisons only; whole-line comments skipped. '
                 'Excludes other names, String/get accessors, match arms, membership lists, '
                 'paths, numeric tuning and declarations. Inline comments/string bodies may match. '
                 'Includes necessary unique skills. Candidates, not a count of remaining tasks '
                 'or a global hardcoding score.',
        'pattern': SELECTORS.pattern,
        'candidate_occurrences': len(rows),
        'by_path': dict(Counter(row['path'] for row in rows)),
        'by_function': dict(Counter(row['path'] + '::' + row['function'] for row in rows).most_common()),
        'rows': rows,
    }
    text = json.dumps(report, ensure_ascii=False, indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text)
        print(json.dumps({key: report[key] for key in ['runtime_scripts_scanned', 'candidate_occurrences', 'by_path']}, ensure_ascii=False))
    else:
        print(text, end='')


if __name__ == '__main__':
    main()
