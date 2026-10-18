"""Narrow lexical inventory of two selectors; not a global hardcoding score."""
import argparse
import json
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', required=True)
    parser.add_argument('--revision', default='WORKTREE')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]

    def source(revision, path):
        if revision == 'WORKTREE':
            return (repo / path).read_text()
        return subprocess.check_output(['git', 'show', revision + ':' + path], cwd=repo, text=True)

    selectors = {
        'src/battle/battle.gd': r'\bmonster_type\s*(?:==|!=|in\b)\s*(?:"|\[|GIANT_RANGED_MONSTER_IDS)',
        'src/hero/hero_projectile.gd': r'\bsource_hero_id\s*(?:==|!=)\s*"[^"\n]+"',
    }
    rows = []
    for path, pattern in selectors.items():
        result = {'path': path}
        for label, revision in [('before', args.baseline), ('after', args.revision)]:
            text = source(revision, path)
            matches = list(re.finditer(pattern, text))
            result[label] = {
                'count': len(matches),
                'lines': [text[:match.start()].count('\n') + 1 for match in matches],
            }
        rows.append(result)
    print(json.dumps({
        'baseline': args.baseline, 'revision': args.revision,
        'scope': 'Two explicit variable selectors only; lexical counts may include comments. '
                 'Does not count other variable names, match arms, unique skills, constants or Catalog declarations. '
                 'Not a percentage of all hardcoding removed or a performance measurement.',
        'selectors': selectors, 'rows': rows,
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
