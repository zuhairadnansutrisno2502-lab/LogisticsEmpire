# Codex (Laptop 1) — START HERE

Single entry point for Codex and any Codex subagents. Read this file once, fully. Open other docs only when a task needs them (token budget). Game design (screens, numbers, statuses): `docs/PROJECT_SPEC.md`. Jobdesks: `docs/ROLES.md`. Visual standards: `docs/CODEX_MASTER_PROMPT.md`.

## 0. Current state (2026-11-04)
- Repo (public): https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire. `main` is protected: PR only, required checks `ownership`, `project-validation`, `python-tests`, `luau-tests`.
- Roblox experience **Logistics Empire**, placeId `104352461543313`, Team Create ON, owner account `tncrabe` (Laptop 1 uses the same account, no invite needed).
- **Laptop 2 (Claude) is the only Rojo integrator.** Every merged PR reaches Studio through Laptop 2. Never connect Rojo to the shared place from Laptop 1.
- **Backend API v0.2 is live** in `main` and in the experience (playtested, persistence verified): `RequestState`, `RequestDispatch`, `RequestVehiclePurchase`, plus events `StateUpdated`, `DeliveryUpdated`, `Notification`. Full contract: `docs/API_CONTRACT.md`. Types: `src/shared/Types`. Catalog/routes/error codes: `src/shared/Contracts`.
- **Planned, not built:** API v0.3 Warehouse + Research ([issue #4](https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire/issues/4)). Build those screens against a mock flagged **MOCK**.
- Client is an empty stub (`src/client/init.client.luau`). All UI, 3D and client code is yours.

## 1. One-time setup on Laptop 1
```
gh auth login                       # browser sign-in; never paste tokens into files
git clone https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire.git
cd LogisticsEmpire
git switch visual/codex
git config core.hooksPath .githooks # pre-push guard: blocks pushes to main, runs CI checks locally
rokit install                       # optional: rojo 7.7.0, lune, selene, stylua (see rokit.toml)
```
Needs Git, Python 3.9+, `gh`. Windows: `winget install Git.Git Python.Python.3.12 GitHub.cli`; the hook runs in Git Bash, so `python` must be on PATH.

**Studio:** sign in as `tncrabe` and open **Logistics Empire**. 3D/Workspace edits sync live with Laptop 2 through Team Create.
**Local preview of your scripts** (never the shared place): `rojo build default.project.json -o preview.rbxlx` and open the file, or `rojo serve --port 34873` + a new blank local place. `*.rbxlx` is gitignored.

## 2. Ownership (CI blocks violations)
| You may edit | Never edit |
|---|---|
| `src/client/**`, `src/shared/VisualConfig/**`, `assets/**`, `docs/quality/CODEX_REVIEW.md` | `src/server/**`, `src/shared/Contracts/**`, `src/shared/Types/**`, `tests/**`, `docs/API_CONTRACT.md`, CI, scripts, shared docs |

Branches: `visual/codex` is your main branch. Parallel subagents use `visual/<task>` (e.g. `visual/fleet-screen`), one writer per folder, each with its own PR to `main`. Need a backend/API change → open an issue labeled `api-change` with example request/response. Do not edit Claude's files.

## 3. Talking to the backend (server is authoritative)
```lua
local RS = game:GetService("ReplicatedStorage")
local Contracts = require(RS:WaitForChild("Shared"):WaitForChild("Contracts"))
local Remotes = RS:WaitForChild("LogisticsRemotes")

local state = Remotes.RequestState:InvokeServer() -- PlayerState (or {ok=false, errorCode})
Remotes.StateUpdated.OnClientEvent:Connect(function(p)
	if p.version > state.version then state = p.state end -- ignore stale updates
end)
Remotes.DeliveryUpdated.OnClientEvent:Connect(function(p) --[[ drive 3D preview from p.delivery ]] end)
Remotes.Notification.OnClientEvent:Connect(function(p) --[[ toast p.message ]] end)

local res = Remotes.RequestDispatch:InvokeServer({ contractId = c.id, vehicleId = v.id, routeId = r.id })
if not res.ok then --[[ map res.errorCode to friendly text: TooSlow, InsufficientFunds, VehicleBusy, ... ]] end
```
- Countdowns: `completesAt - state.serverTime` (plus local elapsed). Never use the client clock as truth.
- Route Planner: routes are `Contracts.Routes` with matching `originId`/`destinationId`. A vehicle fits when its type is in `contract.allowedVehicleTypes`, it is `Available`, its `mode` matches the route and `distanceKm <= maxRangeKm`. Cost and duration previews may use the catalog formulas in `API_CONTRACT.md`, **display only**: the server decides.
- 10 requests/second per player. Disable buttons while a request is in flight.

## 4. Backlog, in order (one small PR each)
1. **App shell + Dashboard:** navy sidebar navigation, light content area, responsive PC/mobile, screen router. Dashboard shows cash, level/xp, active deliveries with countdown, fleet summary, contract preview. Real `RequestState` + `StateUpdated`.
2. **Contracts + Route Planner + Dispatch:** contract list → pick vehicle → pick route → preview → `RequestDispatch` → success/error states.
3. **Fleet:** vehicle cards (status, capacity), buy vehicle (`RequestVehiclePurchase`), rotating 3D vehicle previews for the 4 types.
4. **3D:** isometric HQ diorama + delivery preview scenes (motorcycle urban, truck highway, aircraft flight, ship ocean) driven by `DeliveryUpdated`. Cosmetic only; the UI must work if the preview fails.
5. **Warehouse + Research:** against **MOCK** per issue #4; swap to real remotes when v0.3 merges.
6. **Expansion, Events, Robux Shop:** layout + MOCK only. No purchase prompts or product IDs until backend + owner approval.

Each task: acceptance criteria first; loading/empty/error states; touch targets ≥ 44 px; test in a local preview place (Studio MCP if available); screenshots in the PR.

## 5. Per-task loop
acceptance criteria → implement → self-critique (hierarchy, responsiveness, every button, API use) → local preview test → fix → note evidence in `docs/quality/CODEX_REVIEW.md` → `git push` (the hook runs checks) → PR to `main` with the template → `gh pr checks <n>` → Claude reviews API/security → owner merges → Laptop 2 syncs to Studio.
- Sync your branch with merged work: `python scripts/agent_sync.py --role codex` (clean tree only; it refuses diverged branches).
- After 3 failed fixes on one root cause: write the blocker in the PR/issue and move to independent work.
- Mark anything not actually executed as "not run".

## 6. Token budget
- Read only the docs a task needs; prefer `src/shared/Types` over long docs for payload shapes.
- CI: `gh pr checks <n>`; logs only for failed jobs (`gh run view <id> --log-failed`).
- No polling loops; the hook runs checks and is quiet on success.
- Small PRs; link files/lines in issues instead of pasting code.

## 7. Never
Push to `main`, force push, run Rojo against the shared place, publish the experience, create product IDs or enable purchases, grant currency or decide deliveries on the client, edit Claude-owned paths, redo GitHub/Rojo setup.
