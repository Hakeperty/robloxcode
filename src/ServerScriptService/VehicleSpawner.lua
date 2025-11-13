-- VehicleSpawner.lua
-- Handles spawning vehicles from ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local VehicleSpawner = {}

-- Create the Vehicles folder in ReplicatedStorage if it doesn't exist
local vehiclesFolder = ReplicatedStorage:FindFirstChild("Vehicles")
if not vehiclesFolder then
	vehiclesFolder = Instance.new("Folder")
	vehiclesFolder.Name = "Vehicles"
	vehiclesFolder.Parent = ReplicatedStorage
	print("Created Vehicles folder in ReplicatedStorage")
end

VehicleSpawner.VehiclesFolder = vehiclesFolder

-- Spawn a vehicle for a player
function VehicleSpawner:SpawnVehicle(player, vehicleName)
	-- Look for the vehicle in ReplicatedStorage/Vehicles folder
	local vehicleTemplate = self.VehiclesFolder:FindFirstChild(vehicleName or "2008 Honda CBR1000RR Fireblade")
	
	if not vehicleTemplate then
		-- Try to find any vehicle in the folder
		local vehicles = self.VehiclesFolder:GetChildren()
		if #vehicles > 0 then
			vehicleTemplate = vehicles[1]
			print("Using first available vehicle: " .. vehicleTemplate.Name)
		else
			warn("No vehicles found in ReplicatedStorage/Vehicles folder")
			warn("Please add your bike model to ReplicatedStorage > Vehicles")
			return nil
		end
	end
	
	-- Clone the vehicle
	local newVehicle = vehicleTemplate:Clone()
	
	-- Find spawn location
	local spawnLocation = self:FindSpawnLocation(player)
	if spawnLocation then
		newVehicle:MoveTo(spawnLocation)
	end
	
	newVehicle.Parent = workspace
	
	print("Spawned " .. newVehicle.Name .. " for " .. player.Name)
	return newVehicle
end

-- Find available spawn location
function VehicleSpawner:FindSpawnLocation(player)
	-- Try to find SpawnLocations folder
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
	
	-- Fallback: spawn near player
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		return player.Character.HumanoidRootPart.Position + Vector3.new(5, 3, 0)
	end
	
	-- Default spawn at origin
	return Vector3.new(0, 10, 0)
end

-- Spawn vehicle on player request (call from RemoteEvent)
function VehicleSpawner:OnPlayerRequestVehicle(player, vehicleName)
	local vehicle = self:SpawnVehicle(player, vehicleName)
	
	if vehicle and player.Character then
		-- Wait for vehicle to fully initialize (important for bikes with custom scripts)
		print("⏳ Waiting for vehicle to initialize...")
		task.wait(2)
		print("✓ Vehicle ready!")
		
		-- Find the DriveSeat - try multiple common names in priority order
		local driverSeat = vehicle:FindFirstChild("DriveSeat", true) 
			or vehicle:FindFirstChild("DriverSeat", true)
			or vehicle:FindFirstChild("VehicleSeat", true)
		
		-- If not found, collect all VehicleSeats and log them
		if not driverSeat then
			local foundSeats = {}
			print("🔍 Searching for VehicleSeats in " .. vehicle.Name .. ":")
			for _, child in pairs(vehicle:GetDescendants()) do
				if child:IsA("VehicleSeat") then
					table.insert(foundSeats, child)
					print("   Found VehicleSeat #" .. #foundSeats .. ": " .. child.Name .. " (Path: " .. child:GetFullName() .. ")")
					
					-- Prioritize seats with "Drive" or "Driver" in the name
					if child.Name:lower():find("drive") then
						driverSeat = child
						print("   ✓ Selected (has 'drive' in name)")
					end
				end
			end
			
			-- Use first seat if we found any
			if not driverSeat and #foundSeats > 0 then
				driverSeat = foundSeats[1]
				print("✓ Using seat #1: " .. driverSeat.Name)
			end
		end
		
		-- Still not found? Get any VehicleSeat
		if not driverSeat then
			driverSeat = vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
		end
		
		if driverSeat and driverSeat:IsA("VehicleSeat") then
			-- Teleport player to the seat
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and humanoidRootPart then
				-- Disable any kickstand script temporarily
				local interface = player.PlayerGui:FindFirstChild("Interface")
				if interface then
					local kickstandScript = interface:FindFirstChild("Kickstand", true)
					if kickstandScript and kickstandScript:IsA("LocalScript") then
						kickstandScript.Enabled = false
						print("🔧 Temporarily disabled kickstand script for initial seating")
					end
				end
				
				-- Position player near the seat
				humanoidRootPart.CFrame = driverSeat.CFrame + Vector3.new(0, 5, 0)
				
				-- Wait for physics to settle
				task.wait(0.3)
				
				-- Now sit on the bike
				driverSeat:Sit(humanoid)
				
				-- Wait and re-enable kickstand
				task.wait(0.5)
				if interface then
					local kickstandScript = interface:FindFirstChild("Kickstand", true)
					if kickstandScript and kickstandScript:IsA("LocalScript") then
						kickstandScript.Enabled = true
						print("✓ Re-enabled kickstand script")
					end
				end
				
				print("✓ " .. player.Name .. " seated on " .. vehicle.Name .. " (Seat: " .. driverSeat.Name .. ")")
			end
		else
			warn("DriverSeat/VehicleSeat not found in vehicle: " .. vehicle.Name)
			warn("The bike model should have a VehicleSeat part.")
			warn("Player will spawn near the bike but not seated on it.")
			
			-- At least teleport player near the bike
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart and vehicle.PrimaryPart then
				humanoidRootPart.CFrame = vehicle.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end
	
	return vehicle
end

return VehicleSpawner
