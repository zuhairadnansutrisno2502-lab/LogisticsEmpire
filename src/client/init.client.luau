--!strict
-- Logistics Empire client bootstrap (Claude-owned): builds the data Store and mounts Codex's UI.
local Store = require(script:WaitForChild("Controllers"):WaitForChild("Store"))

local ui = script:FindFirstChild("UI")
local app = ui and ui:FindFirstChild("App")
if app and app:IsA("ModuleScript") then
	require(app).mount(Store)
else
	warn("[Client] Store ready; UI/App not found yet, nothing mounted")
end
