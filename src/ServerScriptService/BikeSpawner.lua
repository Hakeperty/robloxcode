-- BikeSpawner.lua
-- Handles spawning and managing bikes in the game

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local BikeSpawner = {}
BikeSpawner.SpawnPoints = workspace:WaitForChild("SpawnLocations", 10) or workspace

-- Spawn a bike for a player
function BikeSpawner:SpawnBike(player)
	-- Look for Honda CBR bike model
	local bikeModel = ServerStorage:FindFirstChild("2008 Honda CBR1000RR Fireblade") 
		or ServerStorage:FindFirstChild("BikeModel")
		or workspace:FindFirstChild("2008 Honda CBR1000RR Fireblade")
		or workspace:FindFirstChild("BikeModel")
	
	if not bikeModel then
		warn("Honda CBR bike model not found in ServerStorage or Workspace")
		return nil
	end
	
	-- Clone the bike
	local newBike = bikeModel:Clone()
	
	-- Find spawn location
	local spawnLocation = self:FindSpawnLocation()
	if spawnLocation then
		newBike:MoveTo(spawnLocation)
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
	if not driverSeat or not driverSeat:IsA("VehicleSeat") then
		warn("DriveSeat not found or not a VehicleSeat in the bike model.")
		-- Try another common name for vehicle seats
		driverSeat = newBike:FindFirstChild("Seat", true)
		if not driverSeat or not driverSeat:IsA("VehicleSeat") then
			warn("Also tried 'Seat', but no VehicleSeat found.")
			return newBike
		end
	end
	
	-- Temporarily disable the kickstand script to prevent it from interfering
	local kickstandScript = newBike:FindFirstChild("Kickstand", true)
	if kickstandScript and kickstandScript:IsA("Script") then
		kickstandScript.Disabled = true
		print("Kickstand script disabled to allow seating.")
	end

	-- Move character to the seat and sit them
	print("Moving " .. player.Name .. " to the bike seat.")
	character:SetPrimaryPartCFrame(driverSeat.CFrame)
	
	-- Wait a moment for physics to settle before sitting
	task.wait(0.1)

	driverSeat:Sit(humanoid)
	
	-- Verify if the player is seated
	if driverSeat.Occupant == humanoid then
		print("Successfully seated " .. player.Name .. " on the bike.")
	else
		print("Failed to seat " .. player.Name .. ". They are not the occupant.")
	end

	-- Re-enable the kickstand script after a brief delay
	if kickstandScript and kickstandScript:IsA("Script") then
		task.delay(0.5, function()
			kickstandScript.Disabled = false
			print("Kickstand script re-enabled.")
		end)
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
