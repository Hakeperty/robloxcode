-- InitializeGame.lua
-- Server script to initialize game systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== Initializing Bike Game Server ===")

-- Create RemoteEvents folder
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
	print("✓ Created RemoteEvents folder")
end

-- Create SpawnVehicle RemoteEvent
local spawnVehicleEvent = remoteEvents:FindFirstChild("SpawnVehicle")
if not spawnVehicleEvent then
	spawnVehicleEvent = Instance.new("RemoteEvent")
	spawnVehicleEvent.Name = "SpawnVehicle"
	spawnVehicleEvent.Parent = remoteEvents
	print("✓ Created SpawnVehicle RemoteEvent")
end

-- Create Vehicles folder in ReplicatedStorage
local vehiclesFolder = ReplicatedStorage:FindFirstChild("Vehicles")
if not vehiclesFolder then
	vehiclesFolder = Instance.new("Folder")
	vehiclesFolder.Name = "Vehicles"
	vehiclesFolder.Parent = ReplicatedStorage
	print("✓ Created Vehicles folder")
end

print("=== Server initialization complete ===")

-- Load game systems
local GameManager = require(script.Parent:WaitForChild("GameManager"))
local VehicleSpawner = require(script.Parent:WaitForChild("VehicleSpawner"))

-- Setup vehicle spawn event handler
spawnVehicleEvent.OnServerEvent:Connect(function(player, vehicleName)
	print("Player " .. player.Name .. " requested vehicle: " .. tostring(vehicleName))
	VehicleSpawner:OnPlayerRequestVehicle(player, vehicleName)
end)

print("✓ Vehicle spawner connected")
