# Roles and Jobdesks

Who does what. Game design: `docs/PROJECT_SPEC.md`. File ownership (CI-enforced): `docs/OWNERSHIP.md`. Shared rules: `AGENTS.md`.

## Owner (human, account `tncrabe` / GitHub `zuhairadnansutrisno2502-lab`)
- Approves and merges PRs (agents cannot merge on their own).
- Approves anything public or paid: publishing, monetization, product IDs, security/account settings.
- Signs in to Studio and GitHub on both laptops; hands each agent its starting prompt.

## Claude Code — Laptop 2 — Systems + Integrator
**Owns:** `src/server/**`, `src/shared/Contracts/**`, `src/shared/Types/**`, `tests/**`, `docs/API_CONTRACT.md`, `docs/quality/CLAUDE_REVIEW.md`. As integrator: CI, scripts, hooks, shared docs (via `integration/*` PRs).
**Branches:** `systems/claude` (+ `systems/<task>`), `integration/<task>`.

Backlog, in order:
1. **API v0.3 Warehouse + Research** (issue #4): resume local branch `wip/warehouse-research`, add Lune tests, update contract + types, PR, Studio test after merge.
2. **API v0.4 Reputation + premium contracts** (PROJECT_SPEC §9).
3. **Onboarding flag** (`tutorialDone`) when Codex asks.
4. **Expansion service** (regions, extra warehouses), after the owner approves the design.
5. **Event service** (server-driven modifiers).
6. **Monetization** (receipts, entitlements), only after owner approval and real product IDs.
7. **Balance pass** with playtest data (PROJECT_SPEC §6 known issue).
8. **Live multi-server session-lock test** (private server).

Ongoing integrator duties:
- After every merge, run `scripts/integrator_sync.sh` on Laptop 2 so Rojo sends `main` to Studio, then smoke test.
- Keep `docs/SETUP_STATUS.md` current.
- Review Codex PRs for API use and security only.

## Codex — Laptop 1 — Visual / Client
**Owns:** `src/client/**`, `src/shared/VisualConfig/**`, `assets/**`, `docs/quality/CODEX_REVIEW.md`.
**Branches:** `visual/codex` (+ `visual/<task>` for parallel subagents, one writer per folder).

Backlog, in order (details in `docs/CODEX_START_HERE.md` §4):
1. App shell + Dashboard on the live API.
2. Contracts + Route Planner + Dispatch.
3. Fleet screen + 3D vehicle previews.
4. 3D HQ diorama + four delivery scenes.
5. Warehouse + Research screens on MOCK (issue #4) → real API at v0.3.
6. Expansion, Events, Robux Shop: layout + MOCK only.
7. Onboarding flow (PROJECT_SPEC §15).

## Handshakes
| Need | Who starts | How | Done when |
|---|---|---|---|
| New or changed API | Codex or Claude | issue labeled `api-change` with example payloads | Claude merges contract + types + server; Codex swaps out the MOCK |
| Planned feature UI | Codex | build on MOCK from the API issue | real remote wired, MOCK removed |
| Integration in Studio | Claude (Laptop 2) | `integrator_sync.sh` after merge | playtest in Logistics Empire, Output clean |
| Bug found in Studio | whoever finds it | issue with steps + Output | fix PR from the owning side |

## Definition of done (both)
Acceptance criteria met; tests or Studio evidence recorded in your own quality log; CI green; PR reviewed; owner merged; verified in Studio after sync. Report implemented / tested / integrated / blocked separately and mark anything not executed as "not run".
