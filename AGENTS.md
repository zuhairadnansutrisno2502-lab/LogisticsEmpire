# Logistics Empire — Shared Agent Rules

This repository is for ONE shared Roblox experience, **Logistics Empire** (placeId `104352461543313`); do not create or publish another place. Codex owns visual design, UI/UX and art (`src/client/UI`, `src/client/Visuals`, `VisualConfig`, `assets`); Claude owns all technical code: backend, contracts, the client data layer (`src/client/Controllers`, bootstrap), CI and integration. Follow branch and ownership boundaries (`docs/OWNERSHIP.md`). Never force push, auto-merge failing PRs, grant Robux, enable real products, or publish a live experience without explicit approval. Only one Rojo integrator (Laptop 2) syncs the shared Studio tree.

Every task: define acceptance criteria → implement → self-critique → run tests → improve → open PR → cross-review → integration verification. Three failed repair cycles on the same root cause: document blocker, do not silently weaken tests. Update quality logs in your OWN branch. Mark tests 'not run' unless actually executed. Shared documents are changed by proposal/PR, not simultaneous edits. A successful git push is not evidence of Roblox Studio synchronization.

**Setup is done** (Claude, Laptop 2). Do not re-run `docs/CLAUDE_SETUP_ORCHESTRATOR.md`; only fix items in `docs/SETUP_STATUS.md` that are not `DONE`. Codex never redoes GitHub bootstrap or Rojo integration.

## Branches
Codex `visual/codex` (+ `visual/<task>` for parallel subagents), Claude `systems/claude` (+ `systems/<task>`), integrator `integration/<task>`. CI `ownership` maps each prefix to its paths. Codex starts at `docs/CODEX_START_HERE.md`. Jobdesks and backlogs: `docs/ROLES.md`. Game design: `docs/PROJECT_SPEC.md`.

## Guards (both laptops)
- Once per clone: `git config core.hooksPath .githooks`. The pre-push hook blocks pushes to `main` and runs the CI checks (+ Luau tests if `lune` is installed) before anything leaves the laptop.
- GitHub enforces the same on `main`: PR required, checks `ownership`, `project-validation`, `python-tests`, `luau-tests`, no force push.

## Token budget (keep sessions cheap)
- Read only what the task needs: usually `docs/OWNERSHIP.md` + `docs/API_CONTRACT.md` (+ `src/shared/Types` for payload shapes). Open `PROJECT_SPEC.md` / `BRIDGE_RUNBOOK.md` only for design or workflow questions.
- Check CI with `gh pr checks <n>`; read logs only for a failed job: `gh run view <id> --log-failed`.
- Let the pre-push hook run the checks instead of running them by hand first; it is quiet on success.
- Sync with `scripts/agent_sync.py` (no AI involved); never poll GitHub in a loop.
- Small PRs, one feature each. In issues and PRs, link files and line numbers instead of pasting code.
