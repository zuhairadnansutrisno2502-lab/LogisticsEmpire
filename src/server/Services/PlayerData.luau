--!strict
-- Persistence (Claude-owned): one DataStore document per player { data, lock }.
-- Session lock stops two servers writing the same player. A failed load never creates a fresh
-- save over real data: the player is kicked instead (Studio without API access falls back to
-- an unsaved in-memory session so testing still works).
-- Usage: local PlayerData = require(PlayerData)(Rules)

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local STORE_NAME = "LogisticsEmpire_PlayerData_v1"
local LOCK_TTL = 180 -- seconds; a crashed server's lock goes stale after this
local AUTOSAVE_EVERY = 60
local LOAD_ATTEMPTS = 6

return function(Rules: any)
	local PlayerData = {}
	type Session = { state: any, saving: boolean, noSave: boolean }
	local sessions: { [Player]: Session } = {}

	local okStore, store = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	if not okStore then
		warn("[PlayerData] DataStore unavailable:", store)
		store = nil
	end

	local function key(player: Player): string
		return "u_" .. player.UserId
	end

	-- Returns doc table, "locked", or raises on DataStore error.
	local function claim(player: Player): any
		local result: any
		store:UpdateAsync(key(player), function(doc)
			doc = doc or {}
			local lock = doc.lock
			if lock and lock.jobId ~= game.JobId and os.time() - lock.time < LOCK_TTL then
				result = "locked"
				return nil -- abort: no write
			end
			doc.lock = { jobId = game.JobId, time = os.time() }
			result = doc
			return doc
		end)
		return result
	end

	-- Returns state or nil (caller kicks with the message).
	function PlayerData.load(player: Player): (any, string?)
		if not store then
			if RunService:IsStudio() then
				warn("[PlayerData] Studio without DataStore access: in-memory session, NOT saved")
				sessions[player] = { state = Rules.newState(), saving = false, noSave = true }
				return sessions[player].state
			end
			return nil, "Data service unavailable. Please rejoin."
		end
		for _ = 1, LOAD_ATTEMPTS do
			local ok, doc = pcall(claim, player)
			if ok and doc ~= "locked" then
				local state = Rules.migrate(doc.data)
				if not state then
					return nil, "Your save is from a newer game version. Please rejoin later."
				end
				sessions[player] = { state = state, saving = false, noSave = false }
				return state
			end
			if not ok then
				warn("[PlayerData] load failed", player.UserId, doc)
				if RunService:IsStudio() and tostring(doc):find("API") then
					warn("[PlayerData] Studio API access off: in-memory session, NOT saved")
					sessions[player] = { state = Rules.newState(), saving = false, noSave = true }
					return sessions[player].state
				end
			end
			if not player.Parent then
				return nil
			end
			task.wait(5)
		end
		return nil, "Your data is open in another server or unavailable. Please rejoin in a minute."
	end

	function PlayerData.get(player: Player): any
		local s = sessions[player]
		return s and s.state
	end

	local function write(player: Player, s: Session, release: boolean): boolean
		if s.noSave then
			return true
		end
		while s.saving do
			task.wait()
		end
		s.saving = true
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(doc)
				doc = doc or {}
				if doc.lock and doc.lock.jobId ~= game.JobId then
					return nil -- another server owns this player now: never overwrite
				end
				doc.data = s.state
				doc.lock = if release then nil else { jobId = game.JobId, time = os.time() }
				return doc
			end)
		end)
		s.saving = false
		if not ok then
			warn("[PlayerData] save failed", player.UserId, err)
		end
		return ok
	end

	function PlayerData.release(player: Player)
		local s = sessions[player]
		if not s then
			return
		end
		sessions[player] = nil
		for _ = 1, 3 do
			if write(player, s, true) then
				return
			end
			task.wait(2)
		end
	end

	-- Autosave (also refreshes lock time) + save everyone on shutdown.
	function PlayerData.start()
		task.spawn(function()
			while true do
				task.wait(AUTOSAVE_EVERY)
				for player, s in sessions do
					task.spawn(write, player, s, false)
				end
			end
		end)
		game:BindToClose(function()
			local pending = 0
			for player in sessions do
				pending += 1
				task.spawn(function()
					PlayerData.release(player)
					pending -= 1
				end)
			end
			local deadline = os.clock() + 25
			while pending > 0 and os.clock() < deadline do
				task.wait(0.1)
			end
		end)
	end

	return PlayerData
end
