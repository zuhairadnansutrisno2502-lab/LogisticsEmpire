# Logistics Empire

UI-first Roblox logistics tycoon. **One Roblox place, two AI agents on two laptops, working live together.**

## How we work
| | **Codex — Laptop 1** | **Claude Code — Laptop 2** |
|---|---|---|
| Job | Visual design, UI/UX, art | All technical code |
| Works in | Roblox Studio directly (Team Create) via Studio MCP. No git or GitHub needed. | This repo. Rojo pushes merged code into Studio automatically. |
| Owns in the place | `StarterGui` (all UI + UI LocalScripts), `ReplicatedStorage.Art` (Theme, images, small models), `Workspace`, `Lighting` | `ServerScriptService.LogisticsServer`, `ReplicatedStorage.Shared`, `StarterPlayer.StarterPlayerScripts.LogisticsClient` |
| Accounts | its own Roblox account (Team Create editor) | owner GitHub + Roblox `tncrabe` |
| Brief | [`docs/CODEX.md`](docs/CODEX.md) | [`AGENTS.md`](AGENTS.md) |

- **Live:** Team Create shows each laptop's Studio edits to the other within seconds. Claude's code reaches Studio about 30 s after merge (Laptop 2 auto-sync).
- **Never edit the other side's area.** Rojo overwrites anything inside Claude's three paths.
- **Talk through the Team Board** in the place: `ServerStorage.TeamBoard.ToClaude` (Codex writes) and `ServerStorage.TeamBoard.ToCodex` (Claude writes). Read your inbox at the start of every task. Append dated lines; never edit the other side's note.
- **UI data** comes only from the client Store: [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) → Client Store.
- **What to build:** [`docs/PROJECT_SPEC.md`](docs/PROJECT_SPEC.md) (game design) + [`docs/reference/dashboard.webp`](docs/reference/dashboard.webp) (visual target).

## The place
**Logistics Empire**: placeId `104352461543313`, universe `10774614134`, owner `tncrabe`, Team Create on, Drafts off, not published.

## Laptop 2 plumbing
- Auto-sync service (`scripts/install_autosync_macos.sh`, installed): keeps Rojo serving on port 34872 and fast-forwards `main` every 30 s in `~/Projects/LogisticsEmpire-integrator`. Log: `~/Library/Logs/LogisticsEmpire-integrator.log`.
- Studio on Laptop 2 keeps the Rojo plugin connected to `localhost:34872`. After a Studio restart, click Connect once.
- `main` is protected: changes land by PR and must pass the `test` check (`.github/workflows/validate.yml`: project JSON + Lune tests). The pre-push hook (`git config core.hooksPath .githooks`) runs the same checks locally.

## Status (2026-11-04)
- **LIVE:** backend v0.2 (contracts, fleet, routes, timed deliveries, exactly-once payout, persistence), client Store, Laptop 2 auto-sync. Playtested in the place.
- **Next, Claude:** API v0.3 (issue #4): single-level warehouse, research, cargo names, revenue stats, Indonesian cities.
- **Next, Codex:** backlog in `docs/CODEX.md`.
- **Waiting for the owner:** invite Codex's Roblox account to Team Create (Edit); set up Studio MCP for Codex on Laptop 1.

## Safety
Never publish the experience, create product IDs or enable purchases without the owner. The server decides everything. Studio edits roll back via File → Version History; code rolls back via git.
