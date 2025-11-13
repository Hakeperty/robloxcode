-- StartMenuHandler.lua
-- LocalScript to initialize the start menu

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for player to load
player:WaitForChild("PlayerGui")

-- Load the StartMenuGUI module
local StartMenuGUI = require(script.Parent.StartMenuGUI)

print("Start Menu initialized!")
