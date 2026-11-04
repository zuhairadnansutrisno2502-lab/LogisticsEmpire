# Rules for Claude Code (Laptop 2)

Workflow and ownership: `README.md`. Game design: `docs/PROJECT_SPEC.md`. API + Store: `docs/API_CONTRACT.md`. Codex's brief: `docs/CODEX.md`.

**You own:** `src/**`, `tests/**`, `docs/**` and repo tooling. In the place, Rojo puts your code at `ServerScriptService.LogisticsServer`, `ReplicatedStorage.Shared`, `StarterPlayer.StarterPlayerScripts.LogisticsClient`. Through Studio MCP you may read anything, playtest, and write `ServerStorage.TeamBoard.ToCodex`. Never edit Codex's areas: `StarterGui`, `ReplicatedStorage.Art`, `Workspace`, `Lighting`, `TeamBoard.ToClaude`.

**Every task:**
1. `git pull`, then read `ServerStorage.TeamBoard.ToClaude` via Studio MCP (Codex's requests).
2. Write acceptance criteria → implement → Lune tests (`lune run tests/rules.spec.luau`) → self-review (invalid input, duplicates, races, data loss) → PR from `systems/claude` → `test` check green → merge.
3. Within ~30 s auto-sync puts `main` into Studio: playtest via Studio MCP.
4. Append a dated line to `TeamBoard.ToCodex`: what changed for the UI (new Store fields/functions) and anything Codex must do.
5. Log evidence in `docs/quality/CLAUDE_REVIEW.md`. Write "not run" for anything not executed. After 3 failed fixes on one root cause, write the blocker and move on.

**Backlog:** API v0.3 (issue #4) → v0.4 reputation + premium contracts → onboarding flag → expansion → events → monetization (owner approval) → balance pass → live multi-server lock test.

**Never:** publish, create product IDs, enable purchases, force push, trust the client, or rewrite Codex's Studio work.

**Token budget:** read only what the task needs; check CI with `gh pr checks`; logs only for failed jobs.
