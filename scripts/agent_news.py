#!/usr/bin/env python3
"""Start-of-task briefing for either agent. Run before every task and after any merge:

    python scripts/agent_news.py --role codex|claude

1. Shows what landed on main since you last looked (merged PRs, commits).
2. Flags changed files the OTHER side owns that affect you: read them before coding.
3. Syncs your role branch with main (scripts/agent_sync.py: fast-forward or clean merge, never pushes).
4. Lists open PRs and open api-change issues (needs `gh`; skipped if missing).
"""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

# Paths whose changes the given role must read before coding.
WATCH = {
    'codex': ('docs/API_CONTRACT.md', 'src/shared/Types/', 'src/shared/Contracts/', 'src/client/Controllers/',
              'src/client/init.client.luau', 'docs/PROJECT_SPEC.md', 'docs/ROLES.md', 'docs/CODEX_START_HERE.md', 'AGENTS.md'),
    'claude': ('src/client/UI/', 'src/shared/VisualConfig/', 'docs/PROJECT_SPEC.md', 'docs/ROLES.md', 'AGENTS.md'),
}


def run(*cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.stdout.rstrip() if r.returncode == 0 else ''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--role', choices=WATCH, required=True)
    role = parser.parse_args().role
    root = Path(run('git', 'rev-parse', '--show-toplevel'))
    seen_file = Path(run('git', 'rev-parse', '--absolute-git-dir')) / f'agent-news-{role}'

    if subprocess.run(['git', 'fetch', '-q', 'origin', 'main']).returncode:
        print('WARN: fetch failed (offline?); showing local state only')
    new = run('git', 'rev-parse', 'origin/main')
    old = seen_file.read_text().strip() if seen_file.exists() else run('git', 'merge-base', 'HEAD', 'origin/main')

    print(f'== main {old[:7]} -> {new[:7]}')
    if old and old != new:
        print(run('git', 'log', '--oneline', '--first-parent', f'{old}..{new}') or '(no new commits)')
        changed = run('git', 'diff', '--name-only', f'{old}..{new}').splitlines()
        must_read = [f for f in changed if f.startswith(WATCH[role])]
        if must_read:
            print('READ before coding (changed by the other side or shared rules):')
            print(*(f'  {f}' for f in must_read), sep='\n')
    else:
        print('nothing new on main')

    sync = subprocess.run([sys.executable, str(root / 'scripts' / 'agent_sync.py'), '--role', role],
                          capture_output=True, text=True)
    print('branch:', (sync.stdout + sync.stderr).strip())

    if shutil.which('gh'):
        fmt = '.[] | "  #\\(.number) \\(.headRefName // "") \\(.title)"'
        print('open PRs:\n' + (run('gh', 'pr', 'list', '--json', 'number,title,headRefName', '--jq', fmt) or '  none'))
        print('open api-change issues:\n' + (run('gh', 'issue', 'list', '--label', 'api-change', '--json', 'number,title',
                                                  '--jq', '.[] | "  #\\(.number) \\(.title)"') or '  none'))

    if new:
        seen_file.write_text(new)
    return 0


if __name__ == '__main__':
    sys.exit(main())
