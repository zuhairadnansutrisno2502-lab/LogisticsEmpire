# Laptop 1 — Codex onboarding

Repository (private): https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire
Your branch: `visual/codex`. Laptop 2 (Claude) is the **only** Rojo integrator — do not run `rojo serve` against the shared Studio place from Laptop 1.

## 1. Tools
- Git, Python 3.9+, GitHub CLI (`gh`). Windows: `winget install Git.Git Python.Python.3.12 GitHub.cli`
- Optional for local UI previews in a **private test place only**: Roblox Studio, Rokit (`rokit install` reads `rokit.toml`: rojo 7.7.0, selene, stylua, lune).

## 2. GitHub access
The repo owner must give the Laptop 1 GitHub account access (or Laptop 1 signs in as the owner):
```
gh auth login        # interactive browser sign-in, never paste tokens into files
gh repo view zuhairadnansutrisno2502-lab/LogisticsEmpire
```

## 3. Clone and switch
```
git clone https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire.git
cd LogisticsEmpire
git switch visual/codex
```

## 4. Start Codex
Open Codex in the repo with `docs/CODEX_MASTER_PROMPT.md` as the prompt. Codex must NOT redo GitHub bootstrap or Rojo setup (already owned by Claude on Laptop 2, see `docs/SETUP_STATUS.md`).

## 5. Staying in sync
Safe fast-forward from `main` (only when your worktree is clean):
```
python scripts/agent_sync.py --role codex
powershell -ExecutionPolicy Bypass -File scripts/agent_watch.ps1 -Role codex   # optional 60s loop, does not run AI
```

## 6. Review procedure
1. Small PRs from `visual/codex` → `main` using the PR template. CI runs `ownership`, `project-validation`, `python-tests`.
2. You may only change `src/client/**`, `src/shared/VisualConfig/**`, `assets/**`, `docs/quality/CODEX_REVIEW.md` (CI enforces this).
3. Need an API change? Open an Issue with request/response examples, label `api-change`. Claude owns `docs/API_CONTRACT.md`.
4. Claude reviews your PRs for API/security only; the human owner merges. Laptop 2 then syncs `main` into Studio.
5. Build UI against the contract in `docs/API_CONTRACT.md` with a mock adapter clearly flagged as mock until the server is integrated.
