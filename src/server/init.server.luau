--!strict
-- Logistics Empire server bootstrap (Claude-owned): remotes, validation, rate limiting,
-- delivery ticking. Game rules live in Services/Rules (pure), persistence in Services/PlayerData.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contracts = require(ReplicatedStorage.Shared.Contracts)
local Rules = require(script.Services.Rules)(Contracts)
local PlayerData = require(script.Services.PlayerData)(Rules)

local MIN_CALL_INTERVAL = 0.1 -- per player, across all request remotes

-- Remotes ------------------------------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = Contracts.RemoteFolder
local remotes: { [string]: any } = {}
for _, name in Contracts.Functions do
	remotes[name] = Instance.new("RemoteFunction")
	remotes[name].Name = name
	remotes[name].Parent = folder
end
for _, name in Contracts.Events do
	remotes[name] = Instance.new("RemoteEvent")
	remotes[name].Name = name
	remotes[name].Parent = folder
end
folder.Parent = ReplicatedStorage

local function pushState(player: Player, state)
	remotes.StateUpdated:FireClient(player, { version = state.version, state = Rules.view(state, os.time()) })
end

local function finish(player: Player, state, now: number)
	for _, d in Rules.completeDue(state, now) do
		remotes.DeliveryUpdated:FireClient(player, { delivery = d })
		remotes.Notification:FireClient(player, {
			kind = "DeliveryCompleted",
			message = `Delivery complete: +{d.payout} cash`,
			referenceId = d.id,
		})
	end
end

-- Wraps a request handler with load check + rate limit. fn returns the response table.
local lastCall: { [Player]: number } = {}
local function guard(fn: (Player, any, any, number) -> any)
	return function(player: Player, args: any)
		local state = PlayerData.get(player)
		if not state then
			return { ok = false, errorCode = "NotLoaded" }
		end
		local t = os.clock()
		if t - (lastCall[player] or 0) < MIN_CALL_INTERVAL then
			return { ok = false, errorCode = "RateLimited" }
		end
		lastCall[player] = t
		local now = os.time()
		finish(player, state, now) -- settle due deliveries before acting on fresh state
		return fn(player, state, args, now)
	end
end

remotes.RequestState.OnServerInvoke = guard(function(_, state, _, now)
	Rules.refreshBoard(state, now)
	return Rules.view(state, now)
end)

remotes.RequestDispatch.OnServerInvoke = guard(function(player, state, args, now)
	local ok, result = Rules.dispatch(state, args, now)
	if not ok then
		return { ok = false, errorCode = result }
	end
	Rules.refreshBoard(state, now)
	remotes.DeliveryUpdated:FireClient(player, { delivery = result })
	pushState(player, state)
	return { ok = true, deliveryId = result.id }
end)

remotes.RequestVehiclePurchase.OnServerInvoke = guard(function(player, state, args)
	local ok, result = Rules.purchaseVehicle(state, args)
	if not ok then
		return { ok = false, errorCode = result }
	end
	pushState(player, state)
	return { ok = true, vehicleId = result.id }
end)

-- Player lifecycle -----------------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	local state, kickMessage = PlayerData.load(player)
	if not state then
		if player.Parent then
			player:Kick(kickMessage or "Could not load your data. Please rejoin.")
		end
		return
	end
	if not player.Parent then -- left while loading
		PlayerData.release(player)
		return
	end
	local now = os.time()
	finish(player, state, now) -- bounded offline progress: only in-flight deliveries pay out
	Rules.refreshBoard(state, now)
	pushState(player, state)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	lastCall[player] = nil
	PlayerData.release(player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
PlayerData.start()

-- Delivery tick: completes due deliveries and expires contracts while players are online.
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.time()
		for _, player in Players:GetPlayers() do
			local state = PlayerData.get(player)
			if state then
				local before = state.version
				finish(player, state, now)
				Rules.refreshBoard(state, now)
				if state.version ~= before then
					pushState(player, state)
				end
			end
		end
	end
end)

print("Logistics Empire server ready, API", Contracts.Version)
