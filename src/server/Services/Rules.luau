--!strict
-- Pure, synchronous game rules (Claude-owned): player state schema, contracts board, fleet,
-- routes, dispatch, delivery completion. No Roblox APIs and no yields, so every mutation is
-- atomic on the single-threaded server and the whole module runs under Lune tests.
-- ponytail: one rules module for the vertical slice; split into Economy/Fleet/Delivery files
-- when it outgrows ~400 lines.
--
-- Usage: local Rules = require(Rules)(Contracts)
-- Mutating functions return (true, result) or (false, errorCode). They validate everything
-- first and only mutate after the last check, so a rejected call never changes state.

local SCHEMA = 1
local MAX_ID_LEN = 32

return function(C: any)
	local Rules = {}

	local routesById = {}
	for _, r in C.Routes do
		routesById[r.id] = r
	end

	local function newId(state: any, prefix: string): string
		local id = prefix .. state.nextId
		state.nextId += 1
		return id
	end

	local function isId(v: any): boolean
		return type(v) == "string" and #v > 0 and #v <= MAX_ID_LEN
	end

	local function find(list: { any }, id: string): (any, number?)
		for i, item in list do
			if item.id == id then
				return item, i
			end
		end
		return nil, nil
	end

	function Rules.levelFor(xp: number): number
		return math.floor(math.sqrt(xp / 100)) + 1
	end

	function Rules.durationFor(vehicleType: string, route: any): number
		return math.max(1, math.ceil(route.distanceKm / C.Vehicles[vehicleType].speedKmh * C.TimeScale))
	end

	function Rules.costFor(vehicleType: string, route: any): number
		return route.distanceKm * C.Vehicles[vehicleType].costPerKm
	end

	function Rules.newState()
		local state: any = {
			schema = SCHEMA,
			version = 0,
			cash = C.StartingCash,
			xp = 0,
			nextId = 1,
			fleet = {},
			contracts = {},
			activeDeliveries = {},
			warehouses = {},
		}
		table.insert(state.fleet, { id = newId(state, "v"), type = "Motorcycle", level = 1, status = "Available" })
		return state
	end

	-- Returns nil for data written by a newer schema: caller must refuse to load/overwrite it.
	function Rules.migrate(data: any)
		if data == nil then
			return Rules.newState()
		end
		if type(data) ~= "table" or type(data.schema) ~= "number" or data.schema > SCHEMA then
			return nil
		end
		local fresh = Rules.newState()
		for k, v in fresh do
			if data[k] == nil then
				data[k] = v
			end
		end
		data.schema = SCHEMA
		return data
	end

	local function canDrive(vehicleType: string, route: any): boolean
		local v = C.Vehicles[vehicleType]
		return v.mode == route.mode and route.distanceKm <= (v.maxRangeKm or math.huge)
	end

	local function makeContract(state: any, vehicleType: string, now: number)
		local v = C.Vehicles[vehicleType]
		local options = {}
		for _, r in C.Routes do
			if canDrive(vehicleType, r) then
				table.insert(options, r)
			end
		end
		local route = options[math.random(#options)]
		local cargoKg = math.random(math.ceil(v.capacityKg * 0.3), v.capacityKg)
		local allowed = {} -- types that can carry the cargo AND drive some route between the two locations
		for _, t in C.VehicleTypes do
			local fits = C.Vehicles[t].capacityKg >= cargoKg
			for _, r in C.Routes do
				if fits and r.originId == route.originId and r.destinationId == route.destinationId and canDrive(t, r) then
					table.insert(allowed, t)
					break
				end
			end
		end
		local payout = math.floor(Rules.costFor(vehicleType, route) * 2.5 + cargoKg * 0.2) + 20
		return {
			id = newId(state, "c"),
			originId = route.originId,
			destinationId = route.destinationId,
			cargoKg = cargoKg,
			payout = payout,
			xp = math.floor(payout / 10),
			deadlineAt = now + Rules.durationFor(vehicleType, route) * 3 + 300,
			allowedVehicleTypes = allowed,
		}
	end

	-- Drops expired contracts and tops the board up. Always keeps one local motorcycle job
	-- (cost <= PurchaseReserve) so a player can never get stuck: every player keeps the starter
	-- motorcycle, dispatches always pay back more than they cost, and purchases keep the reserve.
	-- ponytail: assumes vehicles are never sold; revisit if selling is added. Returns true if changed.
	function Rules.refreshBoard(state: any, now: number): boolean
		local changed = false
		for i = #state.contracts, 1, -1 do
			if state.contracts[i].deadlineAt <= now then
				table.remove(state.contracts, i)
				changed = true
			end
		end
		while #state.contracts < C.BoardSize do
			local hasStarterJob = false
			for _, c in state.contracts do
				hasStarterJob = hasStarterJob or c.cargoKg <= C.Vehicles.Motorcycle.capacityKg
			end
			local t = if hasStarterJob then C.VehicleTypes[math.random(#C.VehicleTypes)] else "Motorcycle"
			table.insert(state.contracts, makeContract(state, t, now))
			changed = true
		end
		if changed then
			state.version += 1
		end
		return changed
	end

	function Rules.dispatch(state: any, args: any, now: number): (boolean, any)
		if type(args) ~= "table" or not isId(args.contractId) or not isId(args.vehicleId) or not isId(args.routeId) then
			return false, "BadRequest"
		end
		local contract, contractIndex = find(state.contracts, args.contractId)
		if not contract then
			return false, "UnknownContract"
		end
		if contract.deadlineAt <= now then
			return false, "ContractExpired"
		end
		local vehicle = find(state.fleet, args.vehicleId)
		if not vehicle then
			return false, "UnknownVehicle"
		end
		if vehicle.status ~= "Available" then
			return false, "VehicleBusy"
		end
		local route = routesById[args.routeId]
		if not route then
			return false, "UnknownRoute"
		end
		if route.originId ~= contract.originId or route.destinationId ~= contract.destinationId then
			return false, "RouteMismatch"
		end
		if not canDrive(vehicle.type, route) or not table.find(contract.allowedVehicleTypes, vehicle.type) then
			return false, "VehicleNotAllowed"
		end
		if contract.cargoKg > C.Vehicles[vehicle.type].capacityKg then
			return false, "OverCapacity"
		end
		local completesAt = now + Rules.durationFor(vehicle.type, route)
		if completesAt > contract.deadlineAt then
			return false, "TooSlow"
		end
		local cost = Rules.costFor(vehicle.type, route)
		if state.cash < cost then
			return false, "InsufficientFunds"
		end

		-- all checks passed: mutate
		state.cash -= cost
		vehicle.status = "Delivering"
		table.remove(state.contracts, contractIndex :: number)
		local delivery = {
			id = newId(state, "d"),
			contractId = contract.id,
			vehicleId = vehicle.id,
			vehicleType = vehicle.type,
			routeId = route.id,
			originId = contract.originId,
			destinationId = contract.destinationId,
			cargoKg = contract.cargoKg,
			payout = contract.payout,
			xp = contract.xp,
			cost = cost,
			startedAt = now,
			completesAt = completesAt,
			status = "InTransit",
		}
		table.insert(state.activeDeliveries, delivery)
		state.version += 1
		return true, delivery
	end

	-- Awards every due delivery exactly once: the delivery leaves activeDeliveries in the same
	-- synchronous step that pays it, and both live in one saved document.
	function Rules.completeDue(state: any, now: number)
		local done = {}
		for i = #state.activeDeliveries, 1, -1 do
			local d = state.activeDeliveries[i]
			if d.completesAt <= now then
				table.remove(state.activeDeliveries, i)
				state.cash += d.payout
				state.xp += d.xp
				local vehicle = find(state.fleet, d.vehicleId)
				if vehicle then
					vehicle.status = "Available"
				end
				d.status = "Completed"
				table.insert(done, d)
			end
		end
		if #done > 0 then
			state.version += 1
		end
		return done
	end

	function Rules.purchaseVehicle(state: any, args: any): (boolean, any)
		if type(args) ~= "table" or not isId(args.vehicleType) then
			return false, "BadRequest"
		end
		local entry = C.Vehicles[args.vehicleType]
		if not entry or (args.catalogId ~= nil and args.catalogId ~= args.vehicleType) then
			return false, "UnknownCatalogItem"
		end
		if #state.fleet >= C.MaxFleet then
			return false, "FleetFull"
		end
		if state.cash - entry.price < C.PurchaseReserve then
			return false, "InsufficientFunds"
		end
		state.cash -= entry.price
		local vehicle = { id = newId(state, "v"), type = args.vehicleType, level = 1, status = "Available" }
		table.insert(state.fleet, vehicle)
		state.version += 1
		return true, vehicle
	end

	-- Client-facing PlayerState (API_CONTRACT). Remotes serialize a copy, so the live tables
	-- referenced here never reach the client; only server-internal fields are left out.
	function Rules.view(state: any, now: number)
		local fleet = {}
		for _, v in state.fleet do
			table.insert(fleet, {
				id = v.id,
				type = v.type,
				level = v.level,
				status = v.status,
				capacityKg = C.Vehicles[v.type].capacityKg,
			})
		end
		return {
			version = state.version,
			serverTime = now,
			cash = state.cash,
			xp = state.xp,
			level = Rules.levelFor(state.xp),
			fleet = fleet,
			contracts = state.contracts,
			activeDeliveries = state.activeDeliveries,
			warehouses = state.warehouses,
		}
	end

	return Rules
end
