# Codex (Laptop 1) — START HERE

Single entry point for Codex and any Codex subagents. Read this file once, fully. Open other docs only when a task needs them (token budget).
- **Visual target:** `docs/reference/dashboard.webp`. Match its look, layout and art style.
- **Game design** (screens, numbers, LIVE/PLANNED/IDEA): `docs/PROJECT_SPEC.md`. **Jobdesks:** `docs/ROLES.md`. **Visual standards:** `docs/CODEX_MASTER_PROMPT.md`.

## 0. Your role and the current state (2026-11-04)
- **You are the visual designer / UI-UX / art agent.** You design and build every screen, component, layout, animation and image. **Claude does all technical code**: server, data, remotes, the client `Store`, and the bootstrap that mounts your UI. You never call remotes.
- The game is **UI-first with little 3D**. Art is illustrated images like the reference; live 3D is optional and small.
- Repo (public): https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire. `main` is protected: PR only, required checks `ownership`, `project-validation`, `python-tests`, `luau-tests`.
- Roblox experience **Logistics Empire**, placeId `104352461543313`, Team Create ON, owner account `tncrabe` (Laptop 1 uses the same account, no invite needed).
- **Laptop 2 (Claude) is the only Rojo integrator.** Merged PRs reach Studio through Laptop 2. Never connect Rojo to the shared place from Laptop 1.
- Backend API v0.2 is live (contracts, fleet, routes, deliveries, persistence). The client `Store` you consume is **Claude's next task**; until it lands, build against your own `UI/MockStore` with the same interface (§3).
- Planned data (warehouse, research, cargo names, revenue stats, city names): [issue #4](https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire/issues/4). Mock it; never invent backend behaviour.

## 1. One-time setup on Laptop 1
```
gh auth login                       # browser sign-in; never paste tokens into files
git clone https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire.git
cd LogisticsEmpire
git switch visual/codex
git merge --ff-only origin/main
git config core.hooksPath .githooks # pre-push guard: blocks pushes to main, runs CI checks locally
rokit install                       # optional: rojo 7.7.0, lune, selene, stylua (see rokit.toml)
```
Needs Git, Python 3.9+, `gh`. Windows: `winget install Git.Git Python.Python.3.12 GitHub.cli`; the hook runs in Git Bash, so `python` must be on PATH.

**Studio:** sign in as `tncrabe` and open **Logistics Empire** to look; image uploads are done from this account.
**Local preview of your UI** (never the shared place): `rojo build default.project.json -o preview.rbxlx` and open the file, or `rojo serve --port 34873` + a new blank local place. `*.rbxlx` is gitignored. Until Claude's bootstrap mounts `UI/App`, mount it in your preview with a temporary LocalScript that you never commit.

## 2. Ownership (CI blocks violations)
| You may edit | Never edit (Claude / integrator) |
|---|---|
| `src/client/UI/**` (screens, components, `App.luau`, `MockStore.luau`), `src/client/Visuals/**`, `src/shared/VisualConfig/**` (design tokens, image IDs), `assets/**` (source art), `docs/quality/CODEX_REVIEW.md` | `src/client/Controllers/**`, `src/client/init.client.luau`, `src/server/**`, `src/shared/Contracts/**`, `src/shared/Types/**`, `tests/**`, `docs/API_CONTRACT.md`, CI, scripts, shared docs |

Branches: `visual/codex` is your main branch. Parallel subagents use `visual/<task>` (e.g. `visual/dashboard`), one writer per folder, each with its own PR to `main`. Need data the Store doesn't give you → open an issue labeled `api-change` naming the field/function you need.

## 3. The Store interface (your only data source)
Entry point you provide: `src/client/UI/App.luau` returning `{ mount = function(store) ... end }`. Claude's bootstrap calls `App.mount(Store)`.

```lua
-- Store (Claude implements src/client/Controllers/Store.luau; you mirror it in UI/MockStore.luau)
store.get() -> PlayerState                -- shape: src/shared/Types (cash, xp, level, fleet, contracts, activeDeliveries, ...)
store.changed(function(state) end) -> () -> ()        -- subscribe; returns disconnect
store.notified(function(n) end) -> () -> ()           -- n = { kind, message }: show a toast
store.options(contract) -> { { vehicle, route, cost, seconds, onTime } }   -- valid vehicle × route choices
store.dispatch(contractId, vehicleId, routeId) -> (ok, message?)          -- yields; message is player-facing text
store.buyVehicle(vehicleType) -> (ok, message?)
store.progress(delivery) -> number                     -- 0..1, server-time based
store.summary() -> { activeDeliveries, activeRoutes, hubs, fleet = { [VehicleType] = { count, busy } } }
store.mock -> boolean                                  -- true in MockStore: show a small "MOCK" badge
```
- Disable buttons while `dispatch` / `buyVehicle` yield. Show the returned `message` on failure.
- Never compute rewards or completion in the UI. Display only what the Store gives you.
- Fields not live yet (reputation, revenue/min, cargo names, warehouse, research): read them as optional. Show them only when present, or from `MockStore` with the badge.

## 4. Backlog, in order (one small PR each)
1. **Design system** in `VisualConfig`: colours, type scale, spacing, radius, shadows, icon/image IDs. **App shell:** navy sidebar with active pill + VIP promo slot (hidden), top bar (avatar, welcome, cash pill, bell, settings). Responsive: the sidebar collapses to a bottom bar on mobile.
2. **Dashboard** exactly per `PROJECT_SPEC.md` §13 "Dashboard layout": KPI row, network hero, live delivery card with progress bar, contracts list, fleet cards, quick upgrade. Uses `MockStore`.
3. **Contracts + Route Planner:** list → "Terima" → `store.options(contract)` → choice cards (vehicle art, route, cost, time, on-time badge) → `store.dispatch`.
4. **Fleet:** cards per type (art, count, utilization bar), buy vehicle.
5. **Art set (images):** network hero, 4 delivery scenes (motorcycle city, truck highway, aircraft airport, ship port), 4 vehicle images, warehouse, icons, glossy isometric 3D-render style as in the reference. Source files in `assets/`, uploaded from `tncrabe`, IDs in `VisualConfig`.
6. **Warehouse + Research** screens (shapes in issue #4).
7. **Expansion, Events, Robux Shop:** layout only, hidden or MOCK; no purchase prompts.
8. **Onboarding UX** (PROJECT_SPEC §15).

Each task: acceptance criteria first; loading/empty/error states; touch targets ≥ 44 px; check at 1920×1080, 1366×768 and phone size in a local preview place (Studio MCP if available); screenshots + a side-by-side with the reference in the PR.

## 5. Per-task loop
acceptance criteria → design → implement → self-critique (match to reference, hierarchy, spacing, responsiveness, every button) → local preview → fix → note evidence in `docs/quality/CODEX_REVIEW.md` → `git push` (the hook runs checks) → PR to `main` with the template → `gh pr checks <n>` → Claude reviews data use/performance → owner merges → Laptop 2 syncs to Studio.
- Sync your branch with merged work: `python scripts/agent_sync.py --role codex` (clean tree only; it refuses diverged branches).
- After 3 failed fixes on one root cause: write the blocker in the PR/issue and move to independent work.
- Mark anything not actually executed as "not run".

## 6. Token budget
- Read only the docs a task needs; prefer `src/shared/Types` and §3 above for data shapes.
- CI: `gh pr checks <n>`; logs only for failed jobs (`gh run view <id> --log-failed`).
- No polling loops; the hook runs checks and is quiet on success.
- Small PRs; link files/lines in issues instead of pasting code.

## 7. Never
Call remotes or edit Claude's files; push to `main` or force push; run Rojo against the shared place; publish the experience; create product IDs or enable purchases; show gems/VIP/reputation as real before the backend has them; grant currency or decide deliveries in the UI; redo GitHub/Rojo setup.
