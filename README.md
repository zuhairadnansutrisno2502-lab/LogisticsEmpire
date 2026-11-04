# LOGISTICS EMPIRE — Dual Agent Starter v2

UI-first Roblox logistics tycoon starter with separate **Codex visual** and **Claude Opus backend** prompts, GitHub branch ownership enforcement, safe agent polling, CI validation, and single-integrator Rojo workflow.

**NEW: Claude on Laptop 2 owns all automation preparation. Start Claude with `docs/CLAUDE_SETUP_ORCHESTRATOR.md`; Claude performs the GitHub, CI, bridge, onboarding and Rojo preparation where authorized. One-time account login, Roblox Team Create invitations and Studio plugin connection may still require the user. See `docs/SETUP_STATUS.md`.**

**Start here:** `docs/BRIDGE_RUNBOOK.md` → `docs/PROJECT_SPEC.md` → `docs/OWNERSHIP.md` → role prompt in `docs/CODEX_MASTER_PROMPT.md` or `docs/CLAUDE_MASTER_PROMPT.md`.

## Windows quick start
1. Create a **private, empty** GitHub repository named `LogisticsEmpire` (do not initialize README).
2. Extract this ZIP and run in PowerShell from its `LogisticsEmpire` folder:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/bootstrap_repo.ps1 -RepoUrl https://github.com/YOUR_USERNAME/LogisticsEmpire.git
```

3. On laptop 1: `git clone <repo-url>`; `git switch visual/codex`; open Codex with `docs/CODEX_MASTER_PROMPT.md`.
4. On laptop 2: `git clone <repo-url>`; `git switch systems/claude`; open Claude Code with `docs/CLAUDE_MASTER_PROMPT.md`.
5. Optional safe main polling on each laptop: `powershell -ExecutionPolicy Bypass -File scripts/agent_watch.ps1 -Role codex` (or `claude`). This **only fetches and fast-forwards** where safe; it does not run an AI agent, commit, push, or merge divergent branches.
6. After PR review/merge, on one integrator laptop: `powershell -ExecutionPolicy Bypass -File scripts/integrator_sync.ps1 -Serve`. Connect the Rojo Studio plugin in the **existing** Roblox experience. Test mapping on staging first.

**Important:** GitHub repository creation, access grants, Studio plugin connection, and branch protection require authorized account actions. No real-time Studio connection or GitHub automation is running merely because you downloaded this starter. CI covers ownership and starter structural checks; it is **not** a substitute for Luau linting, gameplay tests, or Studio playtests. No auto-merge or auto-publish.
