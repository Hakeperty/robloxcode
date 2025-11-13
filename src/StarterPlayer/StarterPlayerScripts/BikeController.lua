-- BikeController.lua
-- Client-side bike control script

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local BikeController = {}
BikeController.CurrentBike = nil
BikeController.Speed = 50
BikeController.TurnSpeed = 5
BikeController._connections = {}

-- Get current character safely
function BikeController:GetCharacter()
	return player.Character
end

-- Get current humanoid safely
function BikeController:GetHumanoid()
	local character = self:GetCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Initialize bike controls
function BikeController:Initialize()
	print("Bike Controller Initialized for " .. player.Name)
	
	-- Listen for bike mounting
	self:SetupControls()
	
	-- Handle character respawn
	player.CharacterAdded:Connect(function(newCharacter)
		-- Clear current bike when character respawns
		self.CurrentBike = nil
		print("Character respawned, bike controller reset")
	end)
end

-- Setup input controls
function BikeController:SetupControls()
	-- Clear any existing connections
	self:CleanupConnections()
	
	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			self:ToggleBike()
		end
	end)
	table.insert(self._connections, inputConnection)
	
	-- Update loop for bike movement
	local updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if self.CurrentBike then
			self:UpdateBike(deltaTime)
		end
	end)
	table.insert(self._connections, updateConnection)
end

-- Cleanup connections to prevent memory leaks
function BikeController:CleanupConnections()
	for _, connection in ipairs(self._connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	self._connections = {}
end

-- Mount/dismount bike
function BikeController:ToggleBike()
	if self.CurrentBike then
		self:DismountBike()
	else
		self:MountBike()
	end
end

-- Mount the bike
function BikeController:MountBike()
	local character = self:GetCharacter()
	if not character then
		warn("Cannot mount bike: character not found")
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("Cannot mount bike: HumanoidRootPart not found")
		return
	end
	
	-- Find nearest bike in workspace
	local nearestBike = self:FindNearestBike()
	
	if nearestBike and nearestBike.PrimaryPart then
		local distance = (humanoidRootPart.Position - nearestBike.PrimaryPart.Position).Magnitude
		if distance < 10 then
			self.CurrentBike = nearestBike
			print("Mounted bike")
			
			-- Disable character collision
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		else
			warn("Bike too far away: " .. math.floor(distance) .. " studs")
		end
	else
		warn("No nearby bike found")
	end
end

-- Dismount the bike
function BikeController:DismountBike()
	if self.CurrentBike then
		self.CurrentBike = nil
		print("Dismounted bike")
		
		local character = self:GetCharacter()
		if character then
			-- Re-enable character collision
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end
	end
end

-- Find nearest bike
function BikeController:FindNearestBike()
	local character = self:GetCharacter()
	if not character then
		return nil
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return nil
	end
	
	local nearestBike = nil
	local shortestDistance = math.huge
	
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and (obj.Name:find("Bike") or obj.Name:find("bike") or obj.Name:find("CBR") or obj.Name:find("Honda")) then
			local primaryPart = obj.PrimaryPart
			if primaryPart and primaryPart:IsA("BasePart") then
				local distance = (humanoidRootPart.Position - primaryPart.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					nearestBike = obj
				end
			end
		end
	end
	
	return nearestBike
end

-- Update bike movement
function BikeController:UpdateBike(deltaTime)
	local character = self:GetCharacter()
	if not self.CurrentBike or not character then
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	local moveDirection = Vector3.new()
	
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDirection = moveDirection + humanoidRootPart.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDirection = moveDirection - humanoidRootPart.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, math.rad(self.TurnSpeed), 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, -math.rad(self.TurnSpeed), 0)
	end
	
	if moveDirection.Magnitude > 0 then
		local velocity = moveDirection.Unit * self.Speed
		humanoidRootPart.Velocity = Vector3.new(velocity.X, humanoidRootPart.Velocity.Y, velocity.Z)
	end
end

BikeController:Initialize()

return BikeController
