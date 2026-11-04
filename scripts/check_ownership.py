#!/usr/bin/env python3
"""Check changed PR paths against branch ownership.

visual/*      -> Codex paths only (visual/codex, or visual/<task> for parallel subagents)
systems/*     -> Claude paths only
integration/* -> anything EXCEPT agent-owned paths (setup, CI, scripts, shared docs)
"""
import os
import subprocess
import sys

AGENT_PATHS = {
    # Codex: visual design, UI/UX, art
    'visual/': ('src/client/UI/', 'src/client/Visuals/', 'src/shared/VisualConfig/', 'assets/', 'docs/quality/CODEX_REVIEW.md'),
    # Claude: all technical code, incl. the client data layer and bootstrap
    'systems/': ('src/server/', 'src/client/Controllers/', 'src/client/init.client.luau', 'src/shared/Contracts/', 'src/shared/Types/', 'tests/', 'docs/API_CONTRACT.md', 'docs/quality/CLAUDE_REVIEW.md'),
}
ALL_AGENT_PATHS = tuple(p for paths in AGENT_PATHS.values() for p in paths)


def owned(path, prefixes):
    return any(path == p or path.startswith(p) for p in prefixes)


def violations(head, changed):
    """Forbidden paths for this branch, or None if the branch name has no role."""
    for role, paths in AGENT_PATHS.items():
        if head.startswith(role):
            return [p for p in changed if not owned(p, paths)]
    if head.startswith('integration/'):
        return [p for p in changed if owned(p, ALL_AGENT_PATHS)]
    return None


def main():
    head = os.environ.get('HEAD_REF', '')
    base = os.environ.get('BASE_REF', 'origin/main')
    result = subprocess.run(['git', 'diff', '--name-only', f'{base}...HEAD'], capture_output=True, text=True)
    if result.returncode:
        print(result.stderr, file=sys.stderr)
        return 1
    changed = [p for p in result.stdout.splitlines() if p]
    forbidden = violations(head, changed)
    if forbidden is None:
        print(f'Unrecognized branch {head!r}: use visual/*, systems/* or integration/*')
        return 1
    if forbidden:
        print('Ownership violations:', *forbidden, sep='\n - ')
        return 1
    print(f'Ownership OK for {head}: {len(changed)} changed files')
    return 0


if __name__ == '__main__':
    sys.exit(main())
