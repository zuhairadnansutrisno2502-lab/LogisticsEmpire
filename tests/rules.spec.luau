--!strict
-- Run: lune run tests/rules.spec.luau   (pure rules; no Studio needed)
local serde = require("@lune/serde")
local C = require("../src/shared/Contracts")
local Rules = require("../src/shared/Contracts/Rules")(C)

math.randomseed(42)
local passed = 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		error(`FAIL {name}: {err}`, 0)
	end
	passed += 1
end
local function eq(a: any, b: any, msg: string?)
	assert(a == b, `{msg or "eq"}: expected {b}, got {a}`)
end

local NOW = 1_000_000
-- Fixed contract so tests don't depend on randomness.
local function withContract(state, fields: { [string]: any }?)
	local c = {
		id = "c-test",
		originId = "Downtown",
		destinationId = "Suburbs",
		cargoKg = 40,
		payout = 100,
		xp = 10,
		deadlineAt = NOW + 600,
		allowedVehicleTypes = { "Motorcycle", "Truck" },
	}
	for k, v in fields or {} do
		c[k] = v
	end
	table.insert(state.contracts, c)
	return c
end
local function dispatchArgs(over: { [string]: any }?)
	local a: { [string]: any } = { contractId = "c-test", vehicleId = "v1", routeId = "downtown-suburbs" }
	for k, v in over or {} do
		a[k] = v
	end
	return a
end

test("new state: starter cash, one motorcycle", function()
	local s = Rules.newState()
	eq(s.cash, C.StartingCash)
	eq(#s.fleet, 1)
	eq(s.fleet[1].type, "Motorcycle")
	eq(Rules.view(s, NOW).level, 1)
end)

test("board fills and always has a contract the starter fleet can carry", function()
	for _ = 1, 200 do
		local s = Rules.newState()
		assert(Rules.refreshBoard(s, NOW))
		eq(#s.contracts, C.BoardSize)
		local ok = false
		for _, c in s.contracts do
			ok = ok or (c.cargoKg <= 50 and table.find(c.allowedVehicleTypes, "Motorcycle") ~= nil)
			assert(#c.allowedVehicleTypes > 0, "contract with no allowed vehicle")
			assert(c.payout > 0 and c.deadlineAt > NOW)
		end
		assert(ok, "no motorcycle-feasible contract")
	end
end)

test("new player is never stuck: a local motorcycle job they can afford is always on the board", function()
	for _ = 1, 200 do
		local s = Rules.newState()
		s.cash = C.PurchaseReserve
		Rules.refreshBoard(s, NOW)
		local found = false
		for _, c in s.contracts do
			for _, r in C.Routes do
				if not found and r.originId == c.originId and r.destinationId == c.destinationId and table.find(c.allowedVehicleTypes, "Motorcycle") then
					found = Rules.dispatch(s, { contractId = c.id, vehicleId = "v1", routeId = r.id }, NOW)
				end
			end
		end
		assert(found, "no affordable motorcycle dispatch")
	end
end)

test("refresh drops expired contracts", function()
	local s = Rules.newState()
	withContract(s, { deadlineAt = NOW })
	Rules.refreshBoard(s, NOW)
	for _, c in s.contracts do
		assert(c.id ~= "c-test", "expired contract kept")
	end
end)

test("dispatch happy path deducts cost, locks vehicle, removes contract", function()
	local s = Rules.newState()
	withContract(s)
	local ok, d = Rules.dispatch(s, dispatchArgs(), NOW)
	assert(ok, d)
	eq(s.cash, C.StartingCash - 12, "cost = 12 km * 1")
	eq(s.fleet[1].status, "Delivering")
	eq(#s.contracts, 0)
	eq(d.completesAt, NOW + 12)
	eq(#s.activeDeliveries, 1)
end)

test("dispatch rejects bad input without mutating state", function()
	local cases: { { any } } = {
		{ nil, "BadRequest" },
		{ 5, "BadRequest" },
		{ dispatchArgs({ contractId = 1 }), "BadRequest" },
		{ dispatchArgs({ routeId = string.rep("x", 33) }), "BadRequest" },
		{ dispatchArgs({ contractId = "nope" }), "UnknownContract" },
		{ dispatchArgs({ vehicleId = "v999" }), "UnknownVehicle" },
		{ dispatchArgs({ routeId = "moon" }), "UnknownRoute" },
		{ dispatchArgs({ routeId = "downtown-industrial" }), "RouteMismatch" },
	}
	for _, case in cases do
		local s = Rules.newState()
		withContract(s)
		local before = serde.encode("json", s)
		local ok, code = Rules.dispatch(s, case[1], NOW)
		assert(not ok)
		eq(code, case[2])
		eq(serde.encode("json", s), before, "state mutated on " .. case[2])
	end
end)

test("dispatch rule checks", function()
	local s = Rules.newState()
	withContract(s, { deadlineAt = NOW })
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "ContractExpired")

	s = Rules.newState()
	withContract(s, { cargoKg = 60 })
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "OverCapacity")

	s = Rules.newState()
	withContract(s, { allowedVehicleTypes = { "Truck" } })
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "VehicleNotAllowed")

	s = Rules.newState()
	withContract(s, { deadlineAt = NOW + 5 })
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "TooSlow")

	s = Rules.newState()
	s.cash = 11
	withContract(s)
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "InsufficientFunds")

	-- motorcycle on the 1300 km road route (out of range)
	s = Rules.newState()
	withContract(s, { originId = "Industrial", destinationId = "HarborCity", deadlineAt = NOW + 99999 })
	eq(select(2, Rules.dispatch(s, dispatchArgs({ routeId = "industrial-harbor-road" }), NOW)), "VehicleNotAllowed")

	-- aircraft on a road route
	s = Rules.newState()
	s.fleet[1].type = "Aircraft"
	withContract(s, { allowedVehicleTypes = { "Aircraft" } })
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "VehicleNotAllowed")
end)

test("same vehicle / same contract cannot be dispatched twice", function()
	local s = Rules.newState()
	withContract(s)
	withContract(s, { id = "c-2" })
	assert(Rules.dispatch(s, dispatchArgs(), NOW))
	eq(select(2, Rules.dispatch(s, dispatchArgs({ contractId = "c-2" }), NOW)), "VehicleBusy")
	eq(select(2, Rules.dispatch(s, dispatchArgs(), NOW)), "UnknownContract")
end)

test("delivery pays exactly once and releases vehicle", function()
	local s = Rules.newState()
	withContract(s)
	local _, d = Rules.dispatch(s, dispatchArgs(), NOW)
	eq(#Rules.completeDue(s, d.completesAt - 1), 0, "paid early")
	local cash = s.cash
	local done = Rules.completeDue(s, d.completesAt)
	eq(#done, 1)
	eq(done[1].status, "Completed")
	eq(s.cash, cash + 100)
	eq(s.xp, 10)
	eq(s.fleet[1].status, "Available")
	eq(#Rules.completeDue(s, d.completesAt + 999), 0, "paid twice")
	eq(s.cash, cash + 100)
end)

test("offline progress: rejoin after save completes in-flight delivery once", function()
	local s = Rules.newState()
	withContract(s)
	Rules.dispatch(s, dispatchArgs(), NOW)
	local saved = serde.decode("json", serde.encode("json", s)) -- DataStore round trip
	local loaded = Rules.migrate(saved)
	eq(#Rules.completeDue(loaded, NOW + 3600), 1)
	eq(loaded.cash, C.StartingCash - 12 + 100)
	eq(#Rules.completeDue(loaded, NOW + 7200), 0)
end)

test("purchase vehicle", function()
	local s = Rules.newState()
	eq(select(2, Rules.purchaseVehicle(s, { vehicleType = "Truck" })), "InsufficientFunds")
	eq(select(2, Rules.purchaseVehicle(s, { vehicleType = "Bus" })), "UnknownCatalogItem")
	eq(select(2, Rules.purchaseVehicle(s, { vehicleType = "Truck", catalogId = "Ship" })), "UnknownCatalogItem")
	eq(select(2, Rules.purchaseVehicle(s, "Truck")), "BadRequest")
	s.cash = 500 + C.PurchaseReserve - 1
	eq(select(2, Rules.purchaseVehicle(s, { vehicleType = "Motorcycle" })), "InsufficientFunds", "reserve kept")
	s.cash = C.StartingCash
	local ok, v = Rules.purchaseVehicle(s, { vehicleType = "Motorcycle" })
	assert(ok)
	eq(v.type, "Motorcycle")
	eq(s.cash, C.StartingCash - 500)
	eq(#s.fleet, 2)
	s.cash = 10 ^ 9
	while #s.fleet < C.MaxFleet do
		assert(Rules.purchaseVehicle(s, { vehicleType = "Motorcycle" }))
	end
	eq(select(2, Rules.purchaseVehicle(s, { vehicleType = "Motorcycle" })), "FleetFull")
end)

test("ids stay unique across saves", function()
	local s = Rules.newState()
	Rules.refreshBoard(s, NOW)
	local seen = {}
	for _, list in { s.fleet, s.contracts } do
		for _, item in list do
			assert(not seen[item.id], "duplicate id " .. item.id)
			seen[item.id] = true
		end
	end
end)

test("migrate: defaults, partial data, refuses newer schema", function()
	eq(Rules.migrate(nil).cash, C.StartingCash)
	local partial = Rules.migrate({ schema = 1, cash = 5 })
	eq(partial.cash, 5)
	eq(#partial.fleet, 1)
	eq(Rules.migrate({ schema = 99 }), nil)
	eq(Rules.migrate("garbage"), nil)
end)

test("players are isolated", function()
	local a, b = Rules.newState(), Rules.newState()
	withContract(a)
	Rules.dispatch(a, dispatchArgs(), NOW)
	eq(b.cash, C.StartingCash)
	eq(b.fleet[1].status, "Available")
	eq(#b.activeDeliveries, 0)
end)

test("state survives DataStore JSON round trip", function()
	local s = Rules.newState()
	Rules.refreshBoard(s, NOW)
	local copy = serde.decode("json", serde.encode("json", s))
	eq(serde.encode("json", copy), serde.encode("json", s))
end)

test("client options mirror dispatch rules", function()
	local s = Rules.newState()
	local c = withContract(s) -- Downtown -> Suburbs, 40 kg, deadline NOW + 600
	local opts = Rules.options(s, c, NOW)
	eq(#opts, 1, "one motorcycle option")
	eq(opts[1].vehicle.id, "v1")
	eq(opts[1].route.id, "downtown-suburbs")
	eq(opts[1].cost, 12)
	eq(opts[1].seconds, 12)
	assert(opts[1].onTime and opts[1].affordable)
	-- every offered option is accepted by the server
	assert(Rules.dispatch(s, { contractId = c.id, vehicleId = opts[1].vehicle.id, routeId = opts[1].route.id }, NOW))
	eq(#Rules.options(s, c, NOW), 0, "busy vehicle offers nothing")

	local late = Rules.newState()
	local lc = withContract(late, { deadlineAt = NOW + 5 })
	eq(Rules.options(late, lc, NOW)[1].onTime, false)
	local heavy = Rules.newState()
	eq(#Rules.options(heavy, withContract(heavy, { cargoKg = 60 }), NOW), 0, "over capacity offers nothing")
end)

test("progress and summary", function()
	local d = { startedAt = 100, completesAt = 200 }
	eq(Rules.progress(d, 50), 0)
	eq(Rules.progress(d, 150), 0.5)
	eq(Rules.progress(d, 999), 1)
	local s = Rules.newState()
	withContract(s)
	Rules.dispatch(s, dispatchArgs(), NOW)
	Rules.purchaseVehicle(s, { vehicleType = "Motorcycle" })
	local sum = Rules.summary(s)
	eq(sum.activeDeliveries, 1)
	eq(sum.activeRoutes, 1)
	eq(sum.fleet.Motorcycle.count, 2)
	eq(sum.fleet.Motorcycle.busy, 1)
	eq(sum.fleet.Ship.count, 0)
	eq(sum.hubs, #C.Locations)
end)

print(`rules.spec: {passed} passed`)
