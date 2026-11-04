#!/bin/sh
# macOS/Linux twin of integrator_sync.ps1. Run ONLY on the integrator checkout (main).
# Usage: scripts/integrator_sync.sh [--serve]
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
echo "Main updated safely. Re-run with --serve to start Rojo."
