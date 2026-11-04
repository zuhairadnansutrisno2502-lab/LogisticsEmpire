--!strict
-- Shared public types (Claude-owned) for the payloads in docs/API_CONTRACT.md v0.2.
-- Types only: no authoritative values live client-side.

export type VehicleType = "Motorcycle" | "Truck" | "Aircraft" | "Ship"

export type Vehicle = {
	id: string,
	type: VehicleType,
	capacityKg: number,
	level: number,
	status: "Available" | "Delivering" | "Maintenance",
}

export type Contract = {
	id: string,
	originId: string,
	destinationId: string,
	cargoKg: number,
	payout: number,
	xp: number,
	deadlineAt: number,
	allowedVehicleTypes: { VehicleType },
}

export type Delivery = {
	id: string,
	contractId: string,
	vehicleId: string,
	vehicleType: VehicleType,
	routeId: string,
	originId: string,
	destinationId: string,
	cargoKg: number,
	payout: number,
	xp: number,
	cost: number,
	startedAt: number,
	completesAt: number,
	status: "InTransit" | "Completed" | "Failed",
}

export type PlayerState = {
	version: number,
	serverTime: number,
	cash: number,
	xp: number,
	level: number,
	fleet: { Vehicle },
	contracts: { Contract },
	activeDeliveries: { Delivery },
	warehouses: { any },
}

export type Response = { ok: boolean, errorCode: string?, deliveryId: string?, vehicleId: string? }

return {
	VehicleTypes = { "Motorcycle", "Truck", "Aircraft", "Ship" },
	ContractVersion = "0.2",
}
