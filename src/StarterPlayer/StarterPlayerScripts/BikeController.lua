-- BikeController.lua
-- Client-side bike control script

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local BikeController = {}
BikeController.CurrentBike = nil
BikeController.Speed = 50
BikeController.TurnSpeed = 5

-- Initialize bike controls
function BikeController:Initialize()
	print("Bike Controller Initialized for " .. player.Name)
	
	-- Listen for bike mounting
	self:SetupControls()
end

-- Setup input controls
function BikeController:SetupControls()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			self:ToggleBike()
		end
	end)
	
	-- Update loop for bike movement
	RunService.Heartbeat:Connect(function(deltaTime)
		if self.CurrentBike then
			self:UpdateBike(deltaTime)
		end
	end)
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
	-- Find nearest bike in workspace
	local nearestBike = self:FindNearestBike()
	
	if nearestBike and (character.HumanoidRootPart.Position - nearestBike.Position).Magnitude < 10 then
		self.CurrentBike = nearestBike
		print("Mounted bike")
		
		-- Disable character collision
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end

-- Dismount the bike
function BikeController:DismountBike()
	if self.CurrentBike then
		self.CurrentBike = nil
		print("Dismounted bike")
		
		-- Re-enable character collision
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = true
			end
		end
	end
end

-- Find nearest bike
function BikeController:FindNearestBike()
	local nearestBike = nil
	local shortestDistance = math.huge
	
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name:find("Bike") or obj.Name:find("bike") or obj.Name:find("CBR") or obj.Name:find("Honda") then
			local primaryPart = obj:IsA("Model") and obj.PrimaryPart or obj
			if primaryPart and primaryPart:IsA("BasePart") then
				local distance = (character.HumanoidRootPart.Position - primaryPart.Position).Magnitude
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
	if not self.CurrentBike or not character or not character.PrimaryPart then
		return
	end
	
	local moveDirection = Vector3.new()
	
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDirection = moveDirection + character.PrimaryPart.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDirection = moveDirection - character.PrimaryPart.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		character.PrimaryPart.CFrame = character.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(self.TurnSpeed), 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		character.PrimaryPart.CFrame = character.PrimaryPart.CFrame * CFrame.Angles(0, -math.rad(self.TurnSpeed), 0)
	end
	
	if moveDirection.Magnitude > 0 then
		local velocity = moveDirection.Unit * self.Speed
		character.PrimaryPart.Velocity = Vector3.new(velocity.X, character.PrimaryPart.Velocity.Y, velocity.Z)
	end
end

BikeController:Initialize()

return BikeController
