# Roles and Jobdesks

Who does what. Game design: `docs/PROJECT_SPEC.md`. Visual target: `docs/reference/dashboard.webp`. File ownership (CI-enforced): `docs/OWNERSHIP.md`. Shared rules: `AGENTS.md`.

The game is UI-first with little 3D. **Codex = visual design, UI/UX, art. Claude = all technical code.** They meet at one interface: the client `Store` (`docs/CODEX_START_HERE.md` §3).

## Owner (human, Roblox `tncrabe` / GitHub `zuhairadnansutrisno2502-lab`)
- Approves and merges PRs (agents cannot merge on their own).
- Approves anything public or paid: publishing, monetization, product IDs, security/account settings.
- Signs in to Studio and GitHub on both laptops; hands each agent its starting prompt.

## Claude Code — Laptop 2 — all technical code + integrator
**Owns:** `src/server/**`, `src/client/Controllers/**` (Store: remotes, state, validation helpers, error text), `src/client/init.client.luau` (bootstrap that mounts Codex's `UI/App`), `src/shared/Contracts/**`, `src/shared/Types/**`, `tests/**`, `docs/API_CONTRACT.md`, `docs/quality/CLAUDE_REVIEW.md`. As integrator: CI, scripts, hooks, shared docs (via `integration/*` PRs).
**Branches:** `systems/claude` (+ `systems/<task>`), `integration/<task>`.

Backlog, in order:
1. **Client Store + bootstrap:** implement the `Store` interface on the live API v0.2 and mount `UI/App` (falls back to Codex's `UI/MockStore` until the real one exists). This unblocks Codex.
2. **API v0.3** (issue #4): single-level warehouse (Kapasitas / Sorting / Efisiensi), research tree, `cargoType` on contracts, `stats.revenuePerMinute` + trend, Indonesian city map with save migration. Resume branch `wip/warehouse-research` and realign it to this design.
3. **API v0.4:** reputation + premium contracts.
4. Onboarding flag (`tutorialDone`) when Codex asks.
5. Expansion service (regions, extra warehouses), after the owner approves the design.
6. Event service (server-driven modifiers).
7. Monetization (receipts, entitlements, gems/VIP), only after owner approval and real product IDs.
8. Balance pass with playtest data (PROJECT_SPEC §6 known issue).
9. Live multi-server session-lock test.

Ongoing integrator duties:
- After every merge, run `scripts/integrator_sync.sh` on Laptop 2 so Rojo sends `main` to Studio, then smoke test.
- Keep `docs/SETUP_STATUS.md` current.
- Review Codex PRs for data/API use and performance only, never for taste.

## Codex — Laptop 1 — visual design, UI/UX, art
**Owns:** `src/client/UI/**` (screens, components, layout, motion, `MockStore`), `src/client/Visuals/**` (optional small 3D/ViewportFrame bits), `src/shared/VisualConfig/**` (design tokens + image IDs), `assets/**` (source art), `docs/quality/CODEX_REVIEW.md`.
**Branches:** `visual/codex` (+ `visual/<task>` for parallel subagents, one writer per folder).

Backlog, in order (details in `docs/CODEX_START_HERE.md` §4):
1. Design system in `VisualConfig` (colours, type, spacing, radius, shadows) + app shell (sidebar, top bar) matching the reference.
2. Dashboard exactly per PROJECT_SPEC §13 "Dashboard layout", on `MockStore`.
3. Contracts + Route Planner screens.
4. Fleet screen.
5. Art set: network hero, 4 delivery scenes, 4 vehicle images, warehouse, icons (images, uploaded from the owner account).
6. Warehouse + Research screens (v0.3 shapes from issue #4).
7. Expansion, Events, Robux Shop: layout only, hidden or MOCK.
8. Onboarding UX (PROJECT_SPEC §15).

## Handshakes
| Need | Who starts | How | Done when |
|---|---|---|---|
| Data the UI needs | Codex | issue labeled `api-change` naming the Store field/function | Claude ships it in Store (+ server); Codex drops the mock value |
| Planned feature UI | Codex | build on `MockStore` using issue shapes | the real Store returns the same shape |
| Integration in Studio | Claude (Laptop 2) | `integrator_sync.sh` after merge | playtest in Logistics Empire, Output clean, UI matches reference |
| Bug | whoever finds it | issue with steps + Output/screenshot | fix PR from the owning side |

## Definition of done (both)
Acceptance criteria met; evidence (tests, Studio playtest, screenshots for UI) recorded in your own quality log; CI green; PR reviewed; owner merged; verified in Studio after sync. Report implemented / tested / integrated / blocked separately and mark anything not executed as "not run".
