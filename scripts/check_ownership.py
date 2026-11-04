#!/usr/bin/env python3
"""Check changed PR paths against fixed branch ownership; integrator-only files protected."""
import os
import subprocess
import sys

ROLE_PREFIXES = {
    'visual/codex': ('src/client/', 'src/shared/VisualConfig/', 'assets/', 'docs/quality/CODEX_REVIEW.md'),
    'systems/claude': ('src/server/', 'src/shared/Contracts/', 'src/shared/Types/', 'tests/', 'docs/API_CONTRACT.md', 'docs/quality/CLAUDE_REVIEW.md'),
}

def main():
    head = os.environ.get('HEAD_REF', '')
    base = os.environ.get('BASE_REF', 'origin/main')
    # Integration-owned branches are reviewed by integrator; restrict agent branches.
    if head not in ROLE_PREFIXES:
        print(f'Unrecognized PR branch {head!r}: require manual integrator review')
        return 1
    result = subprocess.run(['git', 'diff', '--name-only', f'{base}...HEAD'], capture_output=True, text=True)
    if result.returncode:
        print(result.stderr, file=sys.stderr)
        return 1
    changed = [p for p in result.stdout.splitlines() if p]
    allowed = ROLE_PREFIXES[head]
    forbidden = [p for p in changed if not any(p == prefix or p.startswith(prefix) for prefix in allowed)]
    if forbidden:
        print('Ownership violations:', *forbidden, sep='\n - ')
        return 1
    print(f'Ownership OK for {head}: {len(changed)} changed files')
    return 0

if __name__ == '__main__':
    sys.exit(main())
