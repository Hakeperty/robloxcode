-- SpeedEffects.client.lua
-- Implements speed-based visual effects: speed lines, motion blur, FOV changes, camera shake
-- Uses configuration from VisualEffects module

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Load configuration
local VisualEffects = require(ReplicatedStorage.Modules.VisualEffects)
local Logger
pcall(function()
	Logger = require(ReplicatedStorage.Modules.ClientLogger)
end)

-- State
local currentSpeed = 0 -- km/h
local currentSeat = nil
local baseFOV = VisualEffects.Camera.FOV.BaseFOV
local targetFOV = baseFOV
local speedLinesEnabled = false
local speedLines = {}
local maxSpeedLines = 30

-- Speed Lines System
local function createSpeedLine()
	if not VisualEffects.SpeedLines.Enabled then return nil end
	
	local line = Instance.new("Part")
	line.Name = "SpeedLine"
	line.Size = Vector3.new(VisualEffects.SpeedLines.Width, VisualEffects.SpeedLines.Width, VisualEffects.SpeedLines.Length)
	line.Anchored = true
	line.CanCollide = false
	line.CanQuery = false
	line.CanTouch = false
	line.CastShadow = false
	line.Material = Enum.Material.Neon
	line.Color = VisualEffects.SpeedLines.Color
	line.Transparency = VisualEffects.SpeedLines.Transparency
	
	return line
end

local function updateSpeedLines(dt)
	if not VisualEffects.SpeedLines.Enabled or not currentSeat then
		-- Remove all speed lines
		for i = #speedLines, 1, -1 do
			if speedLines[i] and speedLines[i].Parent then
				speedLines[i]:Destroy()
			end
			table.remove(speedLines, i)
		end
		return
	end
	
	local config = VisualEffects.SpeedLines
	
	-- Calculate intensity based on speed
	local intensity = math.clamp((currentSpeed - config.MinSpeed) / (config.MaxSpeed - config.MinSpeed), 0, 1)
	
	if intensity > 0 then
		-- Spawn new lines
		local spawnChance = intensity * config.SpawnRate * dt
		if math.random() < spawnChance and #speedLines < maxSpeedLines then
			local line = createSpeedLine()
			if line then
				-- Position around the player
				local angle = math.random() * math.pi * 2
				local radius = config.Radius * (0.5 + math.random() * 0.5)
				local offset = Vector3.new(
					math.cos(angle) * radius,
					(math.random() - 0.5) * 10,
					math.sin(angle) * radius
				)
				
				line.CFrame = camera.CFrame * CFrame.new(offset)
				line.Orientation = camera.CFrame:ToOrientation()
				line.Parent = workspace.CurrentCamera
				
				table.insert(speedLines, {
					part = line,
					lifetime = 0,
					maxLifetime = config.Lifetime
				})
			end
		end
	end
	
	-- Update existing lines
	for i = #speedLines, 1, -1 do
		local lineData = speedLines[i]
		if lineData and lineData.part and lineData.part.Parent then
			lineData.lifetime = lineData.lifetime + dt
			
			-- Move line backward relative to camera
			local moveDist = currentSpeed * 0.5 * dt
			lineData.part.CFrame = lineData.part.CFrame * CFrame.new(0, 0, moveDist)
			
			-- Fade out
			local fadeProgress = lineData.lifetime / lineData.maxLifetime
			if fadeProgress > 0.8 then
				local fadeAlpha = (fadeProgress - 0.8) / 0.2
				lineData.part.Transparency = config.Transparency + (1 - config.Transparency) * fadeAlpha
			end
			
			-- Remove if expired or too far
			local distFromCamera = (lineData.part.Position - camera.CFrame.Position).Magnitude
			if lineData.lifetime >= lineData.maxLifetime or distFromCamera > 100 then
				lineData.part:Destroy()
				table.remove(speedLines, i)
			end
		else
			table.remove(speedLines, i)
		end
	end
end

-- Camera FOV System
local function updateFOV(dt)
	if not VisualEffects.Camera.FOV.Enabled or not currentSeat then
		targetFOV = baseFOV
	else
		local config = VisualEffects.Camera.FOV
		local fovProgress = math.clamp(currentSpeed / config.SpeedThreshold, 0, 1)
		targetFOV = config.BaseFOV + (config.MaxFOV - config.BaseFOV) * fovProgress
	end
	
	-- Smooth transition
	local currentFOV = camera.FieldOfView
	local newFOV = currentFOV + (targetFOV - currentFOV) * math.min(1, dt * 10 * VisualEffects.Camera.FOV.TransitionSpeed)
	camera.FieldOfView = newFOV
end

-- Camera Shake System
local shakeOffset = CFrame.new()
local shakeIntensity = 0

local function updateCameraShake(dt)
	if not VisualEffects.Camera.Shake.Enabled or not currentSeat then
		shakeIntensity = 0
		shakeOffset = CFrame.new()
		return
	end
	
	local config = VisualEffects.Camera.Shake
	
	-- Calculate shake intensity based on speed
	if config.SpeedShake then
		local speedFactor = math.clamp(currentSpeed / 200, 0, 1)
		shakeIntensity = config.MaxShakeIntensity * speedFactor
	end
	
	if shakeIntensity > 0 then
		-- Generate shake offset
		local shake = Vector3.new(
			(math.random() - 0.5) * shakeIntensity,
			(math.random() - 0.5) * shakeIntensity,
			(math.random() - 0.5) * shakeIntensity * 0.5
		)
		shakeOffset = CFrame.new(shake)
	else
		shakeOffset = CFrame.new()
	end
end

-- Speed calculation from seat
local function updateSpeed()
	if currentSeat and currentSeat.Parent then
		-- Get velocity and convert to km/h
		local velocity = currentSeat.AssemblyLinearVelocity.Magnitude
		currentSpeed = velocity * 3.6 -- Convert studs/s to km/h (approximate)
	else
		currentSpeed = 0
	end
end

-- Main update loop
local lastUpdate = os.clock()
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local dt = now - lastUpdate
	lastUpdate = now
	
	updateSpeed()
	updateSpeedLines(dt)
	updateFOV(dt)
	updateCameraShake(dt)
	
	-- Apply camera shake if active
	if shakeIntensity > 0 then
		camera.CFrame = camera.CFrame * shakeOffset
	end
end)

-- Track player's seat
local function onSeatChanged(humanoid)
	local seat = humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		currentSeat = seat
		if Logger then
			Logger.Info("SpeedFX", "Mounted", { vehicle = seat.Parent and seat.Parent.Name })
		end
	else
		currentSeat = nil
		if Logger then
			Logger.Info("SpeedFX", "Dismounted")
		end
	end
end

local function setupCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10)
	end
	if humanoid then
		humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
			onSeatChanged(humanoid)
		end)
		onSeatChanged(humanoid)
	end
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

print("✓ Speed Effects initialized")
