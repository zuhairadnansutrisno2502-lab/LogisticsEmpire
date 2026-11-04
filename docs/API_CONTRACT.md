# Logistics Empire — API Contract v0.1

This is an initial proposal, not an implemented API. Both agents must agree before modifying.

## Vehicle types
`Motorcycle | Truck | Aircraft | Ship` (no buses or passenger tickets).

## Server-owned state
`PlayerState = { cash: number, xp: number, level: number, fleet: Vehicle[], activeDeliveries: Delivery[], warehouses: Warehouse[], version: number }`

`Vehicle = { id: string, type: VehicleType, capacityKg: number, level: number, status: "Available"|"Delivering"|"Maintenance" }`

`Contract = { id: string, originId: string, destinationId: string, cargoKg: number, payout: number, deadlineAt: number, allowedVehicleTypes: string[] }`

`Delivery = { id: string, contractId: string, vehicleId: string, routeId: string, startedAt: number, completesAt: number, status: "InTransit"|"Completed"|"Failed" }`

All timestamps are Unix seconds, calculated by the server. Cash and payout are server-owned integers.

## Remote interface (planned)
Client -> Server:
- `RequestState()` -> sanitized PlayerState
- `RequestDispatch({contractId, vehicleId, routeId})` -> `{ok, errorCode?, deliveryId?}`
- `RequestVehiclePurchase({vehicleType, catalogId})` -> `{ok, errorCode?}`
- `RequestWarehouseUpgrade({warehouseId, upgradeId})` -> `{ok, errorCode?}`

Server -> Client:
- `StateUpdated({version, state})`
- `DeliveryUpdated({delivery})`
- `Notification({kind, message, referenceId?})`

Never trust client prices, cargo capacities, cash, delivery timestamps, or completion flags. Validate ownership, availability, capacity, route, rate limits, and balance server-side. Remote transport may use RemoteFunctions/RemoteEvents, but names and payloads must match this contract after agreement.

## 3D preview
PreviewController consumes `DeliveryUpdated` and animates local visual models. It must never award cash or decide delivery success. UI remains playable if the preview fails.

## Monetization
Shop UI requests Roblox purchase prompts; only server-side validated MarketplaceService entitlements and idempotent ProcessReceipt processing may grant benefits. Do not enable live purchases in starter project.
