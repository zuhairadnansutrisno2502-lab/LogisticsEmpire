#!/usr/bin/env python3
"""Safe fast-forward-only integration of origin/main into an agent branch."""
import argparse
import subprocess
import sys

BRANCHES = {'codex': 'visual/codex', 'claude': 'systems/claude'}

def git(*args, check=True):
    result = subprocess.run(['git', *args], capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--role', choices=BRANCHES, required=True)
    args = parser.parse_args()
    expected = BRANCHES[args.role]
    if git('branch', '--show-current') != expected:
        raise RuntimeError(f'Expected branch {expected}; refusing to touch current branch')
    if git('status', '--porcelain'):
        print('SKIP: working tree is dirty; commit/stash first')
        return 2
    git('fetch', 'origin', 'main')
    current = git('rev-parse', 'HEAD')
    base = git('rev-parse', 'origin/main')
    if current == base:
        print('OK: already at origin/main')
        return 0
    # If main is already merged into branch, nothing to do.
    if subprocess.run(['git','merge-base','--is-ancestor',base,current]).returncode == 0:
        print('OK: branch already contains origin/main')
        return 0
    # If agent branch is an ancestor of main, a fast-forward is safe.
    if subprocess.run(['git','merge-base','--is-ancestor',current,base]).returncode == 0:
        git('merge','--ff-only','origin/main')
        print('OK: fast-forwarded to origin/main')
        return 0
    print('BLOCKED: branches diverged; create/review an explicit integration merge or rebase')
    return 3

if __name__ == '__main__':
    try:
        sys.exit(main())
    except (RuntimeError, OSError) as exc:
        print('ERROR:', exc, file=sys.stderr)
        sys.exit(1)
