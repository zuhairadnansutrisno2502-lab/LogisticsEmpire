# Logistics Empire — Shared Agent Rules

Read `docs/PROJECT_SPEC.md`, `docs/API_CONTRACT.md`, `docs/OWNERSHIP.md`, and `docs/BRIDGE_RUNBOOK.md` before modifying anything. This repository is for ONE existing Roblox experience; do not create or publish a new place. Codex owns visual/client UI and 3D assets; Claude owns backend/services and contracts. Follow branch and ownership boundaries. Never force push, auto-merge failing PRs, grant Robux, enable real products, or publish a live experience without explicit approval. Only one Rojo integrator may sync the shared Studio tree.

Every task: define acceptance criteria → implement → self-critique → run tests → improve → open PR → cross-review → integration verification. Three failed repair cycles on the same root cause: document blocker, do not silently weaken tests. Update quality logs in your OWN branch. Mark tests 'not run' unless actually executed. Shared documents are changed by proposal/PR, not simultaneous edits. A successful git push is not evidence of Roblox Studio synchronization.

**Setup owner:** Claude Code Opus on Laptop 2. Before gameplay tasks, Claude must execute `docs/CLAUDE_SETUP_ORCHESTRATOR.md` and update `docs/SETUP_STATUS.md` with verified status. Codex must not attempt duplicate GitHub bootstrap or Rojo integration.
