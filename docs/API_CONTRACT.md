# Logistics Empire — API Contract v0.2

Implemented on `systems/claude` (server vertical slice). Backward-compatible with v0.1: fields were only added; `RequestWarehouseUpgrade` is still planned. Breaking changes go through an `api-change` issue first.

Code sources of truth: `src/shared/Contracts` (remote names, error codes, catalog, routes) and `src/shared/Types` (Luau types for every payload below).

## Vehicle types
`Motorcycle | Truck | Aircraft | Ship` (no buses or passenger tickets).

| Type | capacityKg | speedKmh | costPerKm | price | mode |
|---|---|---|---|---|---|
| Motorcycle | 50 | 60 | 1 | 500 | Road (max 50 km) |
| Truck | 2000 | 80 | 4 | 6000 | Road |
| Aircraft | 20000 | 600 | 25 | 60000 | Air |
| Ship | 200000 | 35 | 8 | 150000 | Sea |

Locations: `Downtown, Suburbs, Industrial, HarborCity`. Routes (`Contracts.Routes`) have `{id, originId, destinationId, mode, distanceKm}`; Industrial→HarborCity has a Road, Air and Sea route, so route choice matters.

Purchases must leave at least `PurchaseReserve` (50) cash, and the board always keeps one local motorcycle job, so a player can never get stuck.

Travel time = `ceil(distanceKm / speedKmh * 60)` seconds. Dispatch cost = `distanceKm * costPerKm`. Level = `floor(sqrt(xp / 100)) + 1`.

## Server-owned state (client receives a copy)
`PlayerState = { version, serverTime, cash, xp, level, fleet: Vehicle[], contracts: Contract[], activeDeliveries: Delivery[], warehouses: [] }`

`Vehicle = { id, type: VehicleType, capacityKg, level, status: "Available"|"Delivering"|"Maintenance" }`

`Contract = { id, originId, destinationId, cargoKg, payout, xp, deadlineAt, allowedVehicleTypes: VehicleType[] }` — `allowedVehicleTypes` only lists types that fit the cargo **and** have a route between origin and destination. Board holds 6; expired contracts are replaced automatically.

`Delivery = { id, contractId, vehicleId, vehicleType, routeId, originId, destinationId, cargoKg, payout, xp, cost, startedAt, completesAt, status: "InTransit"|"Completed"|"Failed" }`

Timestamps are Unix seconds from the server (`serverTime` lets the UI compute countdowns without trusting the client clock). Cash, payout, xp are integers. `version` increases on every change; ignore a `StateUpdated` older than the state you already hold.

## Remotes — `ReplicatedStorage.LogisticsRemotes`
Client → Server (RemoteFunction, `InvokeServer`):
- `RequestState()` → `PlayerState`, or `{ok=false, errorCode}` if not loaded / rate limited
- `RequestDispatch({contractId, vehicleId, routeId})` → `{ok, errorCode?, deliveryId?}`
- `RequestVehiclePurchase({vehicleType, catalogId?})` → `{ok, errorCode?, vehicleId?}` (`catalogId` = vehicle type, optional)
- `RequestWarehouseUpgrade` — planned, not created yet.

Server → Client (RemoteEvent, `OnClientEvent`):
- `StateUpdated({version, state: PlayerState})` — after load, dispatch, purchase, delivery completion, contract expiry
- `DeliveryUpdated({delivery})` — on dispatch (`InTransit`) and completion (`Completed`)
- `Notification({kind, message, referenceId?})` — e.g. `kind="DeliveryCompleted"`

Error codes: `BadRequest, RateLimited, NotLoaded, UnknownContract, ContractExpired, UnknownVehicle, VehicleBusy, UnknownRoute, RouteMismatch, VehicleNotAllowed, OverCapacity, TooSlow, InsufficientFunds, FleetFull, UnknownCatalogItem`. `TooSlow` = the chosen vehicle/route would arrive after `deadlineAt`.

Rate limit: 10 requests/second per player across all request remotes.

## Client Store (what the UI uses) — LIVE in `src/client/Controllers/Store.luau`
Codex's UI (LocalScripts in `StarterGui`) never touches remotes. It gets the Store with
`require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("LogisticsClient"):WaitForChild("Controllers"):WaitForChild("Store"))`.
The bootstrap (`src/client/init.client.luau`) starts the same module, so both share one state.

| Member | Returns | Notes |
|---|---|---|
| `Store.get()` | `PlayerState` or `nil` | `nil` while loading; `changed` fires once loaded |
| `Store.changed(fn)` | disconnect function | `fn(state)` after load and on every newer `StateUpdated` |
| `Store.notified(fn)` | disconnect function | `fn({kind, message, referenceId?})`, e.g. delivery completed |
| `Store.now()` | number | server Unix time (`Workspace:GetServerTimeNow()`); use for every countdown |
| `Store.options(contract)` | `{ {vehicle, route, cost, seconds, onTime, affordable} }` | one entry per Available vehicle type × drivable route, fastest first; computed with the shared `Rules`, so the server accepts every option with `onTime and affordable` |
| `Store.dispatch(contractId, vehicleId, routeId)` | `(ok, message?)` | yields; `message` is Indonesian player-facing text |
| `Store.buyVehicle(vehicleType)` | `(ok, message?)` | yields |
| `Store.progress(delivery)` | number 0..1 | server-time based |
| `Store.summary()` | `{activeDeliveries, activeRoutes, hubs, routes, fleet = {[type] = {count, busy}}}` or `nil` | Dashboard KPIs / fleet cards |
| `Store.catalog()` | `Shared.Contracts` | read-only: vehicles, prices, routes, locations |

`Rules` now lives in `src/shared/Contracts/Rules.luau` (shared by server and client; client use is display-only).

## Sample (new player, for mock adapters)
```lua
{
	version = 1, serverTime = 1793768000, cash = 1000, xp = 0, level = 1,
	fleet = { { id = "v1", type = "Motorcycle", capacityKg = 50, level = 1, status = "Available" } },
	contracts = {
		{ id = "c2", originId = "Downtown", destinationId = "Suburbs", cargoKg = 42, payout = 58, xp = 5,
		  deadlineAt = 1793768336, allowedVehicleTypes = { "Motorcycle", "Truck" } },
	},
	activeDeliveries = {},
	warehouses = {},
}
```

## Server guarantees
Never trusts client prices, capacities, cash, timestamps or completion flags. Every argument is type/length checked; a rejected request never changes state. A delivery pays exactly once: it leaves `activeDeliveries` in the same step that pays it, inside one saved document. Deliveries that finish while offline pay out on next join (only in-flight deliveries, so offline gains are bounded).

## 3D preview
PreviewController consumes `DeliveryUpdated` and animates local visual models. It must never award cash or decide delivery success. UI remains playable if the preview fails.

## Monetization
Shop UI requests Roblox purchase prompts; only server-side validated MarketplaceService entitlements and idempotent ProcessReceipt processing may grant benefits. Not implemented yet; no live purchases in the starter.
