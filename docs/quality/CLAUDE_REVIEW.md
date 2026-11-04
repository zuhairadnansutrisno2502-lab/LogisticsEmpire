# Claude Technical Review Log

Record task, threat model, failure cases, root causes, regression tests, evidence, remaining risks.

## 2026-11-04 — Server vertical slice (PlayerData → Economy → Contract → Fleet → Route → Delivery)

**Acceptance criteria:** new player loads with 1000 cash + 1 motorcycle and a 6-contract board containing at least one job the starter fleet can carry; dispatch validates contract/vehicle/route/capacity/deadline/funds and deducts cost; delivery completes on server time and pays exactly once; vehicle purchase; state saves and survives rejoin; invalid input rejected without mutation; players isolated.

**Design:** `Services/Rules` is pure and synchronous (no Roblox APIs, no yields), so each request mutates state atomically on the single-threaded server and the logic runs under Lune. `Services/PlayerData` owns DataStore. `init.server.luau` owns remotes, rate limit, 1 s delivery tick.

**Threat model / failure cases considered**
- Spoofed args (wrong types, huge strings, foreign ids): strict string/length checks, ids looked up only in the caller's own state → `BadRequest`/`Unknown*`.
- Double dispatch of one vehicle or contract (spam / replay): vehicle must be `Available`, contract is removed on dispatch → `VehicleBusy`/`UnknownContract`.
- Duplicate reward (tick + request racing, rejoin): completion removes the delivery and pays in one non-yielding step; both live in the same saved document, so a rollback to an older save also rolls back the cash.
- Client clock / price tampering: server computes cost, duration, payout; client sends ids only.
- Two servers writing one player: session lock in the document (`lock.jobId`, 180 s TTL refreshed by 60 s autosave). Saves never overwrite a lock owned by another server.
- Load failure: player is kicked, never given a fresh save that could overwrite real data. Newer-schema data is refused (no downgrade). Studio without API access → in-memory session, saving disabled.
- Spam: 0.1 s minimum interval per player across request remotes → `RateLimited`.
- Leave during load: lock released immediately. Leave during autosave: release waits for the in-flight save.
- Stuck player — **defect found in self-review**: first version could leave a new player whose only motorcycle job was the 1300 km road route (cost 1300 > 1000 cash), stuck ~70 min until expiry; also a purchase could drain cash below any job cost. Root cause: no range limit + no cash floor. Fix: motorcycle `maxRangeKm = 50`, board always keeps one motorcycle job, purchases keep `PurchaseReserve = 50`. Regression test: "new player is never stuck" (200 random boards at reserve cash).

**Evidence (actually run, Laptop 2)**
- `lune run tests/rules.spec.luau` → 15 passed (happy path, never-stuck, 8 rejection cases with no-mutation check, rule checks, exactly-once, offline completion after JSON round trip, purchase, unique ids, migration, isolation, DataStore JSON round trip).
- Mutation check: removing the `table.remove` in `completeDue` makes "pays exactly once" fail (test has teeth).
- `selene` (std roblox) on `src/` → 0 errors, 0 warnings. `luau-lsp analyze` (strict) on Rules/Contracts/Types → clean.
- `rojo build default.project.json` → OK.

- **Roblox Studio playtest (2026-11-04, Studio + Rojo 7.7.0, unpublished test place synced from `systems/claude`)**, driven from the client via the remotes:
  - load: cash 1000, level 1, 1 Motorcycle Available, 6 contracts
  - `{contractId=123}` and `"garbage"` → `BadRequest`; back-to-back call → `RateLimited`
  - dispatch c2 Industrial→Suburbs 18 km → ok, cash 982, vehicle Delivering, completes in 18 s
  - replay of the same dispatch → `UnknownContract`
  - after server time: cash 1050 (+68 once), xp 6, vehicle Available; 3 s later still 1050 (paid once)
  - buy Motorcycle → ok (cash 550, fleet 2); buy Ship → `InsufficientFunds`
  - client received StateUpdated ×4, DeliveryUpdated InTransit+Completed, Notification "Delivery complete: +68 cash"
  - unpublished place → DataStore unavailable → in-memory fallback warning, as designed

- **Persistence in the real experience (2026-11-04, after PR #2 merge, Rojo from `main`, Studio API access enabled by owner):**
  - session 1: fresh load cash 1000 → buy Motorcycle (v8) → dispatch 18 s job (payout 74) → stop (BindToClose save). No DataStore warnings.
  - session 2: cash 482, fleet [v1 Delivering, v8 Available], 1 active delivery, version 4 → state survived; delivery then paid: cash 556, xp 7, v1 Available, version 5.
  - session 3: cash 556, xp 7, both vehicles Available, 0 active, version 5 → saved and **not paid twice**.
  - Without API access the same build falls back to an unsaved in-memory session (observed earlier), as designed.

**Not run:** multi-server session-lock contention (Studio JobId is empty, so the lock path between two live servers is untested until a live/private-server test).

**Remaining risks / next:** Studio smoke test of the full loop; Lune CI job (needs an integrator PR to `.github/`); warehouse/research/expansion/monetization services; vehicle selling would break the never-stuck guarantee (noted in code).

## 2026-11-04 — Client Store + bootstrap (ROLES backlog #1)

**Acceptance criteria:** Codex's UI gets all data through one Store (no remotes); state loads with retry while the server reads DataStore; newer `StateUpdated` replaces state and notifies listeners; previews never offer a choice the server rejects; error codes become player-facing text; bootstrap mounts `UI/App` when it exists.

**Design:** `Rules` moved to `src/shared/Contracts/Rules.luau`, so server and client use one copy of the formulas. New pure `Rules.options / progress / summary`. `Store.luau` is thin glue: remotes, listeners (`task.spawn` so a broken UI listener cannot break the Store), version check, `pcall` around `InvokeServer`, server time via `Workspace:GetServerTimeNow()`.

**Threat / failure cases:** stale or out-of-order `StateUpdated` (version check); a remote error or timeout (pcall → fallback message); a UI listener erroring (isolated); a client tampering with previews (display only, the server re-validates); first load racing DataStore (retry every 1 s until state arrives).

**Evidence:** `lune run tests/rules.spec.luau` → 17 passed (new: options mirror dispatch, and every offered option is accepted by `Rules.dispatch`; busy/over-capacity/late cases; progress clamps; summary counts). selene 0/0, luau-lsp strict on shared Rules clean, `rojo build` OK.

**Studio playtest (after merge, auto-sync delivered it in < 1 min):** client required the Store → loaded (cash 556, `Store.now()` within 0.8 s of `serverTime`); summary 2 motorcycles / 0 busy; `options` gave Motorcycle downtown-industrial (25 cash, 25 s); dispatch ok; immediate repeat → "Terlalu cepat, coba lagi" (rate limit); progress 0.07 after ~1 s → 1.00 after delivery; cash 620 (+89 payout); `changed` fired 2×; `notified` got "Delivery complete: +89 cash"; buying a Ship → "Uang tidak cukup".

## 2026-11-04 — Workflow simplified
Codex works directly in Studio (StarterGui / ReplicatedStorage.Art); the repo is Claude-only. Removed the ownership CI, branch roles, agent_news/agent_sync, Windows setup scripts and 13 prompt/setup docs; CI is one `test` job (project JSON + Lune). The bootstrap now only starts the Store; UI LocalScripts require it directly.
