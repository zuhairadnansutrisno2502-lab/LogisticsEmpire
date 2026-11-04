# Laptop 1 — Codex onboarding

Repository (public): https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire
Your branch: `visual/codex`. Laptop 2 (Claude) is the **only** Rojo integrator — do not run `rojo serve` against the shared Studio place from Laptop 1.

## 1. Tools
- Git, Python 3.9+, GitHub CLI (`gh`). Windows: `winget install Git.Git Python.Python.3.12 GitHub.cli`
- Optional for local UI previews in a **private test place only**: Roblox Studio, Rokit (`rokit install` reads `rokit.toml`: rojo 7.7.0, selene, stylua, lune).

## 2. GitHub access
Reading is public; pushing needs the owner account or a collaborator invite (Settings → Collaborators):
```
gh auth login        # interactive browser sign-in, never paste tokens into files
gh repo view zuhairadnansutrisno2502-lab/LogisticsEmpire
```

## 3. Clone and switch
```
git clone https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire.git
cd LogisticsEmpire
git switch visual/codex
git config core.hooksPath .githooks   # pre-push guard: blocks pushes to main, runs CI checks locally
```

## 3b. Studio (live collaboration)
Sign in to Studio as `tncrabe` (owner account, no invite needed) → experience **Logistics Empire** (placeId `104352461543313`, Team Create). Your 3D/Workspace edits sync live to Laptop 2. Scripts only arrive via merged PRs (Laptop 2's Rojo). Never connect your own Rojo to this place.

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
