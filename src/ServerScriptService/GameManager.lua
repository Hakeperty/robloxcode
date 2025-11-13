-- GameManager.lua
-- Main server-side game management script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameManager = {}

-- Initialize the game
function GameManager:Initialize()
	print("=== GameManager Initialize ===")
	
	-- Setup player connection
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
		
		-- Spawn player on bike after character loads
		player.CharacterAdded:Connect(function(character)
			-- Wait for character to fully load
			character:WaitForChild("Humanoid")
			task.wait(0.5)
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
	
	print("✓ GameManager ready")
end

-- Handle player joining
function GameManager:OnPlayerAdded(player)
	print(player.Name .. " has joined the game")
	
	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
	
	local distance = Instance.new("IntValue")
	distance.Name = "Distance"
	distance.Value = 0
	distance.Parent = leaderstats
end

-- Handle player leaving
function GameManager:OnPlayerRemoving(player)
	print(player.Name .. " has left the game")
end

-- Start the game
GameManager:Initialize()

return GameManager
