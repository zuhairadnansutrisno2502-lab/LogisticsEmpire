--!strict
-- Client data Store (Claude-owned): the ONLY data source for Codex's UI. Spec: docs/API_CONTRACT.md "Client Store".
-- Talks to the server remotes, keeps the latest PlayerState, and turns error codes into player-facing text.
-- Previews use the same shared Rules as the server, so the UI never offers a choice the server rejects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ContractsModule = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Contracts")
local Contracts = require(ContractsModule) :: any
local Rules = require(ContractsModule:WaitForChild("Rules") :: ModuleScript)(Contracts)
local remotes = ReplicatedStorage:WaitForChild(Contracts.RemoteFolder)
for _, name in Contracts.Functions do
	remotes:WaitForChild(name)
end

local MESSAGES = {
	InsufficientFunds = "Uang tidak cukup",
	VehicleBusy = "Kendaraan sedang mengirim",
	TooSlow = "Terlalu lambat untuk tenggat. Pilih kendaraan atau rute yang lebih cepat",
	OverCapacity = "Muatan terlalu berat",
	VehicleNotAllowed = "Kendaraan ini tidak bisa memakai rute ini",
	ContractExpired = "Kontrak sudah tidak tersedia",
	UnknownContract = "Kontrak sudah tidak tersedia",
	FleetFull = "Armada penuh (maks 20)",
	LicenseRequired = "Riset lisensinya dulu",
	RateLimited = "Terlalu cepat, coba lagi",
	NotLoaded = "Data masih dimuat",
}
local FALLBACK = "Terjadi kesalahan, coba lagi"

local state: any = nil
local onChange: { (any) -> () } = {}
local onNotify: { (any) -> () } = {}

local function emit(list: { (any) -> () }, value: any)
	for _, fn in list do
		task.spawn(fn, value) -- a broken UI listener can't break the Store
	end
end

local function listen(list: { (any) -> () }, fn: (any) -> ()): () -> ()
	table.insert(list, fn)
	return function()
		local i = table.find(list, fn)
		if i then
			table.remove(list, i)
		end
	end
end

local function accept(newState: any)
	if type(newState) == "table" and newState.version and (not state or newState.version > state.version) then
		state = newState
		emit(onChange, state)
	end
end

local function call(name: string, args: any): (boolean, string?)
	local remote = remotes:FindFirstChild(name) :: RemoteFunction
	local ok, res = pcall(remote.InvokeServer, remote, args)
	if not ok or type(res) ~= "table" then
		return false, FALLBACK
	end
	if res.ok then
		return true, nil
	end
	return false, MESSAGES[res.errorCode] or FALLBACK
end

local stateUpdated = remotes:WaitForChild("StateUpdated") :: RemoteEvent
local notification = remotes:WaitForChild("Notification") :: RemoteEvent
stateUpdated.OnClientEvent:Connect(function(payload)
	accept(payload and payload.state)
end)
notification.OnClientEvent:Connect(function(n)
	emit(onNotify, n)
end)

task.spawn(function() -- first load; the server may still be reading DataStore
	local remote = remotes:FindFirstChild("RequestState") :: RemoteFunction
	while not state do
		local ok, res = pcall(remote.InvokeServer, remote)
		if ok then
			accept(res)
		end
		if not state then
			task.wait(1)
		end
	end
end)

local Store = { mock = false }

function Store.get(): any -- nil while loading; Store.changed fires once loaded
	return state
end

function Store.changed(fn: (any) -> ()): () -> ()
	return listen(onChange, fn)
end

function Store.notified(fn: (any) -> ()): () -> ()
	return listen(onNotify, fn)
end

function Store.now(): number -- server Unix time; use for all countdowns
	return Workspace:GetServerTimeNow()
end

function Store.options(contract: any): { any }
	return if state then Rules.options(state, contract, Store.now()) else {}
end

function Store.dispatch(contractId: string, vehicleId: string, routeId: string): (boolean, string?)
	return call("RequestDispatch", { contractId = contractId, vehicleId = vehicleId, routeId = routeId })
end

function Store.buyVehicle(vehicleType: string): (boolean, string?)
	return call("RequestVehiclePurchase", { vehicleType = vehicleType })
end

function Store.progress(delivery: any): number
	return Rules.progress(delivery, Store.now())
end

function Store.summary(): any
	return if state then Rules.summary(state) else nil
end

function Store.catalog(): any -- read-only game data: Vehicles, Routes, Locations, prices
	return Contracts
end

return Store
