--!strict
-- Logistics Empire client bootstrap (Claude-owned): starts the data Store.
-- Codex's UI (LocalScripts in StarterGui) requires the same Store module; see docs/API_CONTRACT.md.
require(script:WaitForChild("Controllers"):WaitForChild("Store"))
