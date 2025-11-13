-- StartMenuHandler.lua
-- LocalScript to initialize the start menu

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for player to load
player:WaitForChild("PlayerGui")

-- Load the StartMenuGUI module with error handling
local success, result = pcall(function()
	return require(script.Parent.StartMenuGUI)
end)

if success then
	print("✓ Start Menu initialized successfully!")
else
	warn("⚠ Failed to initialize Start Menu: " .. tostring(result))
	warn("The game menu may not work properly.")
end
