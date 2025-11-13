-- BikeSpawner.lua
-- Handles spawning and managing bikes in the game

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BikeSpawner = {}
BikeSpawner.SpawnPoints = workspace:WaitForChild("SpawnLocations", 10) or workspace

-- Spawn a bike for a player
function BikeSpawner:SpawnBike(player)
	-- Look for Honda CBR bike model in multiple locations
	local bikeModel = ReplicatedStorage:FindFirstChild("Vehicles") and ReplicatedStorage.Vehicles:FindFirstChild("2008 Honda CBR1000RR Fireblade")
		or ServerStorage:FindFirstChild("2008 Honda CBR1000RR Fireblade") 
		or ServerStorage:FindFirstChild("BikeModel")
		or workspace:FindFirstChild("2008 Honda CBR1000RR Fireblade")
		or workspace:FindFirstChild("BikeModel")
	
	if not bikeModel then
		warn("Honda CBR bike model not found in ReplicatedStorage/Vehicles, ServerStorage, or Workspace")
		warn("Please add the bike model to ReplicatedStorage > Vehicles folder")
		return nil
	end
	
	-- Clone the bike
	local newBike = bikeModel:Clone()
	
	-- Find spawn location
	local spawnLocation = self:FindSpawnLocation()
	if spawnLocation and newBike.PrimaryPart then
		newBike:SetPrimaryPartCFrame(CFrame.new(spawnLocation))
	elseif spawnLocation then
		-- If no PrimaryPart, try to move the first BasePart
		for _, child in ipairs(newBike:GetChildren()) do
			if child:IsA("BasePart") then
				child.Position = spawnLocation
				break
			end
		end
	end
	
	newBike.Parent = workspace
	
	-- Get player's character and humanoid
	local character = player.Character
	if not character then
		warn("Player character not found for " .. player.Name)
		return newBike
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("Humanoid not found for " .. player.Name)
		return newBike
	end

	-- Find the driver's seat in the bike model
	local driverSeat = newBike:FindFirstChild("DriveSeat", true)
		or newBike:FindFirstChild("DriverSeat", true)
		or newBike:FindFirstChild("Seat", true)
	
	if not driverSeat or not driverSeat:IsA("VehicleSeat") then
		warn("DriveSeat not found or not a VehicleSeat in the bike model.")
		-- Try to find any VehicleSeat
		driverSeat = newBike:FindFirstChildWhichIsA("VehicleSeat", true)
		if not driverSeat then
			warn("No VehicleSeat found in the bike model at all.")
			return newBike
		else
			print("Found VehicleSeat: " .. driverSeat.Name)
		end
	end

	-- Move character to the seat and sit them
	print("Moving " .. player.Name .. " to the bike seat.")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CFrame = driverSeat.CFrame + Vector3.new(0, 5, 0)
	end
	
	-- Wait a moment for physics to settle before sitting
	task.wait(0.2)

	driverSeat:Sit(humanoid)
	
	-- Verify if the player is seated
	task.wait(0.1)
	if driverSeat.Occupant == humanoid then
		print("Successfully seated " .. player.Name .. " on the bike.")
	else
		warn("Failed to seat " .. player.Name .. ". Attempting again...")
		task.wait(0.1)
		driverSeat:Sit(humanoid)
		task.wait(0.1)
		if driverSeat.Occupant == humanoid then
			print("Successfully seated " .. player.Name .. " on second attempt.")
		else
			warn("Could not seat player on bike after multiple attempts.")
		end
	end
	
	print("Spawned bike for " .. player.Name)
	return newBike
end

-- Find available spawn location
function BikeSpawner:FindSpawnLocation()
	local spawnParts = workspace:FindFirstChild("SpawnLocations")
	
	if spawnParts then
		local spawns = spawnParts:GetChildren()
		if #spawns > 0 then
			local randomSpawn = spawns[math.random(1, #spawns)]
			if randomSpawn:IsA("BasePart") then
				return randomSpawn.Position + Vector3.new(0, 5, 0)
			end
		end
	end
	
	-- Default spawn at origin
	return Vector3.new(0, 10, 0)
end

return BikeSpawner
