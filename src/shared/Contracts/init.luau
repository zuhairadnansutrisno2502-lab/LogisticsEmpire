--!strict
-- Shared API contract + game catalog (Claude-owned). Mirrors docs/API_CONTRACT.md v0.2.
-- Pure data, no Roblox APIs: loads in Studio and in Lune tests. Public (ReplicatedStorage).

return {
	Version = "0.2",

	RemoteFolder = "LogisticsRemotes",
	Functions = { "RequestState", "RequestDispatch", "RequestVehiclePurchase" }, -- RemoteFunction
	Events = { "StateUpdated", "DeliveryUpdated", "Notification" }, -- RemoteEvent (server -> client)

	ErrorCodes = {
		"BadRequest",
		"RateLimited",
		"NotLoaded",
		"UnknownContract",
		"ContractExpired",
		"UnknownVehicle",
		"VehicleBusy",
		"UnknownRoute",
		"RouteMismatch",
		"VehicleNotAllowed",
		"OverCapacity",
		"TooSlow",
		"InsufficientFunds",
		"FleetFull",
		"UnknownCatalogItem",
	},

	VehicleTypes = { "Motorcycle", "Truck", "Aircraft", "Ship" },

	-- catalogId == vehicle type. price/costPerKm are integers (cash).
	Vehicles = {
		Motorcycle = { capacityKg = 50, speedKmh = 60, costPerKm = 1, price = 500, mode = "Road", maxRangeKm = 50 },
		Truck = { capacityKg = 2000, speedKmh = 80, costPerKm = 4, price = 6000, mode = "Road" },
		Aircraft = { capacityKg = 20000, speedKmh = 600, costPerKm = 25, price = 60000, mode = "Air" },
		Ship = { capacityKg = 200000, speedKmh = 35, costPerKm = 8, price = 150000, mode = "Sea" },
	},

	Locations = { "Downtown", "Suburbs", "Industrial", "HarborCity" },

	Routes = {
		{ id = "downtown-suburbs", originId = "Downtown", destinationId = "Suburbs", mode = "Road", distanceKm = 12 },
		{ id = "downtown-industrial", originId = "Downtown", destinationId = "Industrial", mode = "Road", distanceKm = 25 },
		{ id = "industrial-suburbs", originId = "Industrial", destinationId = "Suburbs", mode = "Road", distanceKm = 18 },
		{ id = "industrial-harbor-road", originId = "Industrial", destinationId = "HarborCity", mode = "Road", distanceKm = 1300 },
		{ id = "industrial-harbor-air", originId = "Industrial", destinationId = "HarborCity", mode = "Air", distanceKm = 900 },
		{ id = "industrial-harbor-sea", originId = "Industrial", destinationId = "HarborCity", mode = "Sea", distanceKm = 1100 },
	},

	-- Real seconds per in-game hour of travel. 60 => a 12 km motorcycle trip takes 12 s.
	TimeScale = 60,
	StartingCash = 1000,
	BoardSize = 6,
	MaxFleet = 20,
	-- Cash a purchase must leave behind: covers any local motorcycle job, so nobody gets stuck.
	PurchaseReserve = 50,
}
