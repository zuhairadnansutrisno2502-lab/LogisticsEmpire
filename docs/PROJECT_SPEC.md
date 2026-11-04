# LOGISTICS EMPIRE — Game Design Document

Single source of truth for what the game is. Status tags: **LIVE** (in `main`, Studio-tested) · **PLANNED** (designed, API issue exists) · **IDEA** (direction only; needs owner approval before anyone builds it). Numbers marked LIVE come from `src/shared/Contracts`; if this doc and the code disagree, the code wins and this doc gets fixed.

## 1. Pitch and pillars
UI-first Roblox logistics tycoon: grow a delivery company from one courier motorcycle to a fleet of trucks, cargo aircraft and container ships.
- **Clear decisions:** every dispatch is a choice of contract × vehicle × route against a deadline and a cost.
- **Steady progression:** every delivery funds the next upgrade.
- **Calm, beautiful UI:** light surfaces, navy sidebar, readable at a glance on PC and mobile.
- **3D that rewards:** HQ diorama, vehicle previews and delivery cinematics make progress visible. Cosmetic only.
- **Fair and safe:** the server decides everything; monetization never breaks the economy.

**Out of scope:** avatar driving, buses/passengers, PvP, combat, trading between players. Exactly four vehicle types: Motorcycle, Truck, Aircraft, Ship.
**Platforms:** PC, mobile, tablet (console-safe layout). Target session 5–15 min, many returning sessions.

## 2. Core loop — LIVE
Contract board → pick contract → pick vehicle → pick route → preview cost / travel time / payout → dispatch (server deducts cost) → wait real seconds (3D preview plays) → server pays once + XP → reinvest → bigger contracts.
**Meta loop:** level up and reinvest in fleet, research and warehouses (PLANNED), then unlock regions (IDEA).

## 3. World and routes — LIVE
Locations: Downtown, Suburbs, Industrial, HarborCity. Routes are one-way (origin → destination). Time scale: 1 in-game travel hour = 60 real seconds.

| Route id | From → To | Mode | km | Vehicles (travel s / cost) |
|---|---|---|---|---|
| downtown-suburbs | Downtown → Suburbs | Road | 12 | Motorcycle 12 s / 12 · Truck 9 s / 48 |
| downtown-industrial | Downtown → Industrial | Road | 25 | Motorcycle 25 s / 25 · Truck 19 s / 100 |
| industrial-suburbs | Industrial → Suburbs | Road | 18 | Motorcycle 18 s / 18 · Truck 14 s / 72 |
| industrial-harbor-road | Industrial → HarborCity | Road | 1300 | Truck 975 s / 5200 |
| industrial-harbor-air | Industrial → HarborCity | Air | 900 | Aircraft 90 s / 22500 |
| industrial-harbor-sea | Industrial → HarborCity | Sea | 1100 | Ship 1886 s / 8800 |

## 4. Fleet — LIVE (licenses PLANNED)
| Type | Capacity kg | Speed km/h | Cost/km | Price | Mode | Notes |
|---|---|---|---|---|---|---|
| Motorcycle | 50 | 60 | 1 | 500 | Road | max 50 km; every player starts with one |
| Truck | 2,000 | 80 | 4 | 6,000 | Road | |
| Aircraft | 20,000 | 600 | 25 | 60,000 | Air | needs Aviation License (PLANNED) |
| Ship | 200,000 | 35 | 8 | 150,000 | Sea | needs Maritime License (PLANNED) |

Max fleet 20. Vehicle status: Available / Delivering / Maintenance (Maintenance reserved for Events, IDEA). Vehicle levels exist in data; vehicle upgrades are IDEA.

## 5. Contracts — LIVE
- Board of 6 per player. Expired contracts are replaced automatically. The board always keeps one local job a motorcycle can carry.
- A contract is generated for one vehicle type on a route that type can drive. Cargo is 30–100% of that type's capacity.
- `payout = floor(baseCost × 2.5 + cargoKg × 0.2) + 20`, `xp = floor(payout / 10)`, `deadline = now + 3 × base travel time + 300 s`.
- `allowedVehicleTypes` = every type that can carry the cargo and drive some route between the two locations.
- Dispatch is rejected if the vehicle would arrive after the deadline (`TooSlow`), so every accepted delivery is on time.

## 6. Economy — LIVE
- Start: 1,000 cash, 1 Motorcycle. Level = `floor(sqrt(xp / 100)) + 1`.
- Dispatch cost is paid upfront; payout and XP arrive on completion, exactly once.
- Every purchase must leave **50 cash** (`PurchaseReserve`). Together with the guaranteed motorcycle job this means a player can never get stuck.
- Typical early numbers: a motorcycle job costs 12–25 and pays ~55–90; a local truck job costs 48–100 and pays ~260–670.

**Balance targets (to tune after playtests):** first Truck within ~15 min, first Aircraft ~2 h, first Ship ~6 h.
**Known balance issue:** an Aircraft job (90 s, ~35k profit) earns far more per minute than Truck or Ship, and starter progress to the first Truck is slower than the target. Tune before release, for example with lower air payout, contract scarcity, or turnaround time.

## 7. Warehouse — PLANNED v0.3 (issue #4)
Every player owns one Downtown warehouse with two upgrade tracks (max level 5, level n→n+1 costs `baseCost × 2^n`):
- **Storage** (base 1,000): +10% payout per level for jobs that start at that location.
- **Automation** (base 1,500): +5 cash per minute per level, paid in whole minutes; offline accrual capped at 8 h.

More warehouses come with Expansion (IDEA). The 3D warehouse visibly grows with level.

## 8. Research — PLANNED v0.3 (issue #4)
One-time cash purchases with prerequisites. Percentage effects stack.

| Id | Name | Cost | Requires | Effect |
|---|---|---|---|---|
| routing1 | Route Optimization I | 1,500 | — | dispatch cost −10% |
| fastLoading | Fast Loading | 3,000 | — | travel time −10% |
| routing2 | Route Optimization II | 8,000 | routing1 | dispatch cost −10% more |
| aviation | Aviation License | 25,000 | routing1 | can buy Aircraft |
| maritime | Maritime License | 60,000 | routing2 | can buy Ship |

## 9. Reputation — PLANNED v0.4
Not in the API yet: the UI shows **no** reputation until the field exists.
- Design: 0–5 stars, earned from completed deliveries weighted by cargo tier. Higher stars unlock premium contracts (payout multiplier) and Expansion requirements.
- Events (IDEA) can cost reputation, for example when a vehicle breaks down.

## 10. Expansion — IDEA
Unlock new regions (more locations and routes, international hubs) and extra warehouses for cash + level (+ reputation). Each region adds contracts and a 3D map tile.

## 11. Events — IDEA
Timed, server-driven global modifiers announced via `Notification`, for example rush hour (+road payout), storms (slower ships), or air traffic surges. Never decided by the client.

## 12. Monetization — IDEA (owner approval required)
VIP pass (small payout bonus + cosmetic badge), vehicle skins, cinematic delivery previews, dashboard themes, optional cash packs.
- Rules: MarketplaceService entitlements checked on the server, idempotent `ProcessReceipt`, purchase recovery, centralized product config.
- No invented product IDs, and no live purchases before approval. Paid boosts stay modest.

## 13. Screens and UX
Global layout: navy left sidebar (icons + labels, collapses to a bottom bar on mobile), light content area, a top bar with cash / level / XP progress, and toast notifications. Every screen has loading, empty and error states.

| Screen | Shows | Actions | API / status |
|---|---|---|---|
| Dashboard | company name, cash, level/XP bar, active deliveries with countdown, fleet summary, top contracts, 3D HQ | jump to Contracts / Fleet | LIVE: `RequestState`, `StateUpdated` |
| Contracts | board cards: route, cargo, payout, XP, deadline countdown, allowed vehicles | open Route Planner | LIVE |
| Route Planner | chosen contract, eligible vehicles, routes between its locations, preview of cost / time / arrival vs deadline | Dispatch | LIVE: `RequestDispatch` (preview is display only) |
| Fleet | vehicle cards with 3D rotating model, status, capacity, active job | Buy vehicle | LIVE: `RequestVehiclePurchase` (licenses PLANNED) |
| Warehouse | 3D warehouse, storage/automation levels, next cost, income/min | Upgrade | PLANNED v0.3 → MOCK |
| Research | tree with locked / available / done nodes | Research | PLANNED v0.3 → MOCK |
| Expansion | region map | — | IDEA → layout + MOCK |
| Events | active/upcoming events | — | IDEA → layout + MOCK |
| Robux Shop | product cards | none until approved | IDEA → layout only |

**Error messages** (map `errorCode` → text):
- `InsufficientFunds` → "Not enough cash"
- `VehicleBusy` → "Vehicle is on a delivery"
- `TooSlow` → "Too slow for the deadline: try a faster vehicle or route"
- `OverCapacity` → "Cargo too heavy"
- `VehicleNotAllowed` → "This vehicle can't take this route"
- `ContractExpired` / `UnknownContract` → "Contract no longer available"
- `RateLimited` → silent retry
- `FleetFull` → "Fleet is full (20)"
- `LicenseRequired` → "Research the license first"
- anything else → "Something went wrong"

## 14. Visual and 3D direction
- Palette: Primary blue `#2D6FE1`, Background `#F7F9FC` (`VisualConfig`), navy sidebar, white cards, rounded corners, generous spacing, one accent colour. Never a dense dark dashboard.
- 3D: isometric HQ diorama that grows with progress; rotating vehicle previews; four delivery scenes (motorcycle urban, truck highway, aircraft airport/flight, ship port/ocean) driven by `DeliveryUpdated`.
- Performance: low-poly, one preview scene at a time, and previews disabled on low-end devices. The UI must work without 3D.
- Audio (IDEA): soft UI clicks and a delivery-complete chime.

## 15. Onboarding — PLANNED (client only)
First run, guided on real state: highlight the motorcycle job → choose the route → dispatch → watch the preview → collect → suggest buying a second motorcycle. Skippable. A persisted "tutorial done" flag needs a backend field (Claude, on request).

## 16. Multiplayer, persistence and safety — LIVE
Each player has an isolated company; there is no interaction between players (leaderboards IDEA). One DataStore document per player with a session lock, schema migration, autosave and shutdown save. A failed load never overwrites data. Remotes are validated and rate limited (10/s). Offline progress is bounded: only in-flight deliveries pay (+ capped automation in v0.3).

## 17. Roadmap
| Version | Content | Status |
|---|---|---|
| v0.2 | Core loop: contracts, fleet, routes, delivery, persistence | LIVE (backend) / UI in progress (Codex) |
| v0.3 | Warehouse + Research | PLANNED (issue #4) |
| v0.4 | Reputation + premium contracts | PLANNED |
| v0.5 | Expansion (regions, extra warehouses) | IDEA |
| v0.6 | Events | IDEA |
| v0.7 | Monetization | IDEA, owner approval |

## 18. Release acceptance
A new player completes the loop (load → dispatch → paid once → upgrade → save/rejoin). Duplicate rewards are impossible, players are isolated, the UI is responsive on PC and mobile, it matches this visual direction, there are no critical errors in Output, and all of it is verified in Roblox Studio, not only by reading files.
