# Codex brief — Logistics Empire (Laptop 1)

**You are the visual design / UI-UX / art agent.** Claude Code (Laptop 2) does all technical code. You work **directly in Roblox Studio** in the shared place. You do not need git or a GitHub account: read the docs from the public URLs below.

Docs (public, read-only):
- This brief: https://raw.githubusercontent.com/zuhairadnansutrisno2502-lab/LogisticsEmpire/main/docs/CODEX.md
- Game design: https://raw.githubusercontent.com/zuhairadnansutrisno2502-lab/LogisticsEmpire/main/docs/PROJECT_SPEC.md
- Store API: https://raw.githubusercontent.com/zuhairadnansutrisno2502-lab/LogisticsEmpire/main/docs/API_CONTRACT.md
- Visual target: https://raw.githubusercontent.com/zuhairadnansutrisno2502-lab/LogisticsEmpire/main/docs/reference/dashboard.webp

## 1. Setup (once)
1. Roblox Studio, signed in with **your** Roblox account. The owner invites you to the Team Create of **Logistics Empire** (placeId `104352461543313`) with Edit permission. Open it.
2. Connect to Studio through its MCP server. Studio ships a `StudioMCP` executable (Windows: under `%LOCALAPPDATA%\Roblox\Versions\<version>\`), or use Roblox's official Studio MCP setup. Verify that you can list the open Studio and read the DataModel.
3. Any UI code you already wrote locally: move it into the place (Section 2). There is nothing to push.

## 2. Where you work in the place
| Yours | Never touch |
|---|---|
| `StarterGui` (every ScreenGui + its LocalScripts), `ReplicatedStorage.Art` (`Theme` ModuleScript with colours/type/spacing/image IDs, images, small models), `Workspace`, `Lighting`, `ServerStorage.TeamBoard.ToClaude` (your outbox) | `ServerScriptService.LogisticsServer`, `ReplicatedStorage.Shared`, `StarterPlayer.StarterPlayerScripts.LogisticsClient` (Rojo overwrites these from Claude's repo), `ServerStorage.TeamBoard.ToCodex` |

Team Create is live: Claude and the owner see your edits within seconds. Don't delete or rewrite things you didn't create. Rollback is File → Version History.

## 3. Data: the Store (never call remotes)
```lua
local Players = game:GetService("Players")
local Store = require(Players.LocalPlayer:WaitForChild("PlayerScripts")
	:WaitForChild("LogisticsClient"):WaitForChild("Controllers"):WaitForChild("Store"))

Store.changed(function(state) --[[ re-render ]] end) -- also fires once after the first load
local state = Store.get()                             -- nil while loading: show a loading state
local ok, message = Store.dispatch(contractId, vehicleId, routeId) -- yields; message is Indonesian text
```
Full API: `API_CONTRACT.md` → Client Store (`get, changed, notified, now, options, dispatch, buyVehicle, progress, summary, catalog`).
- Countdowns and progress bars: `Store.now()` / `Store.progress(delivery)`.
- Route Planner: `Store.options(contract)` lists only choices the server accepts.
- Not live yet (reputation, revenue/min, cargo names, warehouse, research, gems, VIP): treat as optional. Hide them, or show a small "SEGERA" badge.

## 4. Team Board (how you and Claude talk)
- **Start of every task:** read `ServerStorage.TeamBoard.ToCodex` (Claude's notes: what changed, new Store fields).
- **Need data or behaviour:** append a dated line to `ServerStorage.TeamBoard.ToClaude` with what you need and an example. Claude replies in `ToCodex`.

## 5. Backlog (in order)
1. **Theme + app shell:** `ReplicatedStorage.Art.Theme` (colours, type scale, spacing, radius, shadows). A ScreenGui with the navy sidebar (active pill), the top bar (avatar, welcome, cash pill, bell, settings) and a content area. Responsive: the sidebar becomes a bottom bar on phones.
2. **Dashboard** exactly per `PROJECT_SPEC.md` §13 "Dashboard layout", live from the Store.
3. **Contracts + Route Planner:** list → "Terima" → `Store.options` cards (vehicle art, route, cost, time, on-time badge) → `Store.dispatch`.
4. **Fleet:** cards per type (art, count, utilization bar) + buy vehicle.
5. **Art set (images):** network hero, 4 delivery scenes, 4 vehicles, warehouse, icons, glossy isometric 3D-render style. Upload them, give experience `10774614134` permission to use each asset (Creator Hub → asset → Permissions), and keep the IDs in `Theme`.
6. **Warehouse + Research** screens (shapes in GitHub issue #4), "SEGERA" until live.
7. **Expansion, Events, Robux Shop:** layout only, hidden.
8. **Onboarding** (`PROJECT_SPEC.md` §15).

## 6. Done means
Matches the reference; Indonesian copy; loading/empty/error states; touch targets ≥ 44 px. Tested in Studio Play (Client) at 1920×1080, 1366×768 and phone size, with screenshots. A dated line in `TeamBoard.ToClaude` says what you finished and what you need. Report done / tested / blocked honestly.

## 7. Never
Grant currency or decide deliveries in the UI, call remotes, edit Claude's areas, publish the experience, create product IDs or enable purchases.
