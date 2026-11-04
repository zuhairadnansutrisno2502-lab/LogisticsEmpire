#!/bin/sh
# macOS/Linux twin of integrator_sync.ps1. Run ONLY on the integrator checkout (main).
# Usage: scripts/integrator_sync.sh            # fast-forward main once + checks
#        scripts/integrator_sync.sh --serve    # ... then run Rojo in the foreground
#        scripts/integrator_sync.sh --watch    # keep Rojo up + fast-forward main every 30 s (Ctrl+C stops)
set -e
cd "$(dirname "$0")/.."
[ "$(git branch --show-current)" = "main" ] || { echo "Integrator must use main branch" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Working tree must be clean" >&2; exit 1; }
if git remote get-url origin >/dev/null 2>&1; then
  git fetch origin main
  git merge --ff-only origin/main || { echo "Main diverged; refusing unsafe merge" >&2; exit 1; }
else
  echo "WARN: no origin remote yet; serving local main only"
fi
python3 -m json.tool default.project.json >/dev/null
python3 scripts/test_project.py
if [ "$1" = "--serve" ]; then
  echo "Starting Rojo. Open the EXISTING (or staging copy) place in Studio and click Connect in the Rojo plugin."
  exec rojo serve default.project.json
fi
if [ "$1" = "--watch" ]; then
  echo "Watching origin/main every 30 s and keeping Rojo up on 34872. Merged PRs reach Studio automatically."
  set +e
  while :; do
    curl -s --max-time 2 http://localhost:34872/api/rojo >/dev/null || { echo "$(date '+%H:%M:%S') starting rojo"; rojo serve default.project.json >/dev/null 2>&1 & }
    before=$(git rev-parse HEAD)
    if git fetch -q origin main 2>/dev/null && git merge -q --ff-only origin/main 2>/dev/null; then
      [ "$before" = "$(git rev-parse HEAD)" ] || echo "$(date '+%H:%M:%S') synced main -> $(git log --oneline -1)"
    else
      echo "$(date '+%H:%M:%S') sync skipped (offline, dirty or diverged)"
    fi
    sleep 30
  done
fi
echo "Main updated safely. Use --watch to keep syncing, or --serve to start Rojo."
