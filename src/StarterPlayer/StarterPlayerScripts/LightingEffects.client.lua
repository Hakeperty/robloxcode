-- LightingEffects.client.lua
-- Manages bike lighting effects: headlight, taillight, brake lights, turn signals
-- Uses configuration from VisualEffects module

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- Load configuration
local VisualEffects = require(ReplicatedStorage.Modules.VisualEffects)
local Logger
pcall(function()
	Logger = require(ReplicatedStorage.Modules.ClientLogger)
end)

-- State
local currentBike = nil
local currentSeat = nil
local lights = {}
local isBraking = false
local lastThrottle = 0

-- Lighting Manager
local LightingManager = {}

-- Find lighting attachment points on bike
local function findLightAttachments(bike)
	local attachments = {
		headlight = nil,
		taillight = nil,
		leftTurn = nil,
		rightTurn = nil
	}
	
	for _, inst in ipairs(bike:GetDescendants()) do
		local name = string.lower(inst.Name)
		
		if inst:IsA("Attachment") or inst:IsA("BasePart") then
			if name:find("headlight") or name:find("frontlight") then
				attachments.headlight = inst
			elseif name:find("taillight") or name:find("rearlight") or name:find("backlight") then
				attachments.taillight = inst
			elseif name:find("turnleft") or name:find("leftturn") then
				attachments.leftTurn = inst
			elseif name:find("turnright") or name:find("rightturn") then
				attachments.rightTurn = inst
			end
		end
	end
	
	return attachments
end

-- Create a spotlight
local function createSpotLight(parent, config)
	local light = Instance.new("SpotLight")
	light.Brightness = config.Brightness or 1
	light.Range = config.Range or 30
	light.Angle = config.Angle or 90
	light.Color = config.Color or Color3.new(1, 1, 1)
	light.Face = Enum.NormalId.Front
	light.Enabled = false
	
	if parent:IsA("Attachment") then
		-- Create a part to hold the light at the attachment
		local lightPart = Instance.new("Part")
		lightPart.Name = "LightHolder"
		lightPart.Size = Vector3.new(0.1, 0.1, 0.1)
		lightPart.Transparency = 1
		lightPart.CanCollide = false
		lightPart.CanQuery = false
		lightPart.CanTouch = false
		lightPart.Anchored = false
		lightPart.Parent = parent.Parent
		
		-- Weld to attachment parent
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = parent.Parent
		weld.Part1 = lightPart
		weld.Parent = lightPart
		
		light.Parent = lightPart
	else
		light.Parent = parent
	end
	
	return light
end

-- Create a point light
local function createPointLight(parent, config)
	local light = Instance.new("PointLight")
	light.Brightness = config.Brightness or 1
	light.Range = config.Range or 15
	light.Color = config.Color or Color3.new(1, 0, 0)
	light.Enabled = false
	light.Parent = parent
	
	return light
end

-- Attach lights to bike
function LightingManager:AttachToBike(bike)
	self:DetachFromBike()
	currentBike = bike
	
	if not bike then return end
	
	local attachments = findLightAttachments(bike)
	
	-- Create headlight
	if VisualEffects.Lighting.Headlight.Enabled and attachments.headlight then
		lights.headlight = createSpotLight(attachments.headlight, VisualEffects.Lighting.Headlight)
		if Logger then
			Logger.Info("Lights", "HeadlightCreated", { parent = attachments.headlight:GetFullName() })
		end
	end
	
	-- Create taillight / brake light
	if VisualEffects.Lighting.Taillight.Enabled and attachments.taillight then
		lights.taillight = createPointLight(attachments.taillight, VisualEffects.Lighting.Taillight)
		if Logger then
			Logger.Info("Lights", "TaillightCreated", { parent = attachments.taillight:GetFullName() })
		end
	end
	
	-- Update lighting based on time of day
	self:UpdateLighting()
	
	if Logger then
		Logger.Info("Lights", "Attached", { bike = bike.Name, lightCount = 0 })
		for name, light in pairs(lights) do
			if light then
				Logger.Info("Lights", "LightCreated", { name = name })
			end
		end
	end
end

-- Cleanup lights
function LightingManager:DetachFromBike()
	for name, light in pairs(lights) do
		if light and light.Parent then
			-- If light is in a holder part, destroy the holder
			if light.Parent.Name == "LightHolder" then
				light.Parent:Destroy()
			else
				light:Destroy()
			end
		end
	end
	lights = {}
	currentBike = nil
end

-- Update lighting state
function LightingManager:UpdateLighting(telemetry)
	if not currentBike then return end
	
	-- Update brake state from telemetry
	if telemetry then
		local throttle = telemetry.throttle or 0
		isBraking = throttle < lastThrottle - 0.2 -- Simple brake detection
		lastThrottle = throttle
	end
	
	-- Auto-toggle headlight based on time of day
	if lights.headlight and VisualEffects.Lighting.Headlight.Enabled then
		local config = VisualEffects.Lighting.Headlight
		
		if config.AutoToggle then
			local timeOfDay = Lighting.ClockTime
			-- Turn on headlight between 6 PM and 6 AM
			local shouldBeOn = timeOfDay >= config.ToggleAtTime or timeOfDay < 6
			lights.headlight.Enabled = shouldBeOn
		else
			lights.headlight.Enabled = true
		end
	end
	
	-- Update taillight / brake light
	if lights.taillight and VisualEffects.Lighting.Taillight.Enabled then
		local config = VisualEffects.Lighting.Taillight
		lights.taillight.Enabled = true
		
		-- Increase brightness when braking
		if isBraking then
			lights.taillight.Brightness = config.BrakeIntensity
		else
			lights.taillight.Brightness = config.Brightness
		end
	end
end

-- Connect to telemetry for brake detection
local function connectTelemetry()
	local playerGui = player:WaitForChild("PlayerGui")
	
	local function bindEvent(evt)
		if evt and evt:IsA("BindableEvent") then
			evt.Event:Connect(function(data)
				LightingManager:UpdateLighting(data)
			end)
		end
	end
	
	local telemetryEvent = playerGui:FindFirstChild("HelmetTelemetry")
	if telemetryEvent then
		bindEvent(telemetryEvent)
	end
	
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "HelmetTelemetry" and child:IsA("BindableEvent") then
			bindEvent(child)
		end
	end)
end

-- Track seat changes
local function onSeatChanged(humanoid)
	local seat = humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		currentSeat = seat
		local bike = seat.Parent
		LightingManager:AttachToBike(bike)
	else
		currentSeat = nil
		LightingManager:DetachFromBike()
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

-- Initialize
player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

connectTelemetry()

-- Update lighting periodically
RunService.Heartbeat:Connect(function()
	if currentBike then
		LightingManager:UpdateLighting()
	end
end)

print("✓ Lighting Effects initialized")

return LightingManager
