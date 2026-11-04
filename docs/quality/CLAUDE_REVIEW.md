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

**Not run:** DataStore persistence/session lock against real servers (needs the PR merged into the published experience and API access), multi-server lock contention.

**Remaining risks / next:** Studio smoke test of the full loop; Lune CI job (needs an integrator PR to `.github/`); warehouse/research/expansion/monetization services; vehicle selling would break the never-stuck guarantee (noted in code).
