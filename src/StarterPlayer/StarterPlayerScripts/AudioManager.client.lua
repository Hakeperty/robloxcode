-- AudioManager.client.lua
-- Manages motorcycle audio effects based on SoundConfig
-- Handles engine sounds, transmission, exhaust, tires, and ambient audio

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- Load configuration
local SoundConfig = require(ReplicatedStorage.Modules.SoundConfig)
local Logger
pcall(function()
	Logger = require(ReplicatedStorage.Modules.ClientLogger)
end)

-- State
local currentBike = nil
local currentSeat = nil
local sounds = {}
local lastRPM = 0
local lastSpeed = 0
local lastGear = "N"
local lastTelemetryTime = 0

-- Audio Manager
local AudioManager = {}
AudioManager.Enabled = true
AudioManager.MasterVolume = SoundConfig.Master.MasterVolume

-- Helper to create sound
local function createSound(name, soundId, parent, properties)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = properties.Volume or 0.5
	sound.Looped = properties.Looped or false
	sound.PlaybackSpeed = properties.PlaybackSpeed or 1
	
	if properties.RollOffMode then
		sound.RollOffMode = Enum.RollOffMode[properties.RollOffMode]
	end
	if properties.RollOffMaxDistance then
		sound.RollOffMaxDistance = properties.RollOffMaxDistance
	end
	if properties.RollOffMinDistance then
		sound.RollOffMinDistance = properties.RollOffMinDistance
	end
	
	sound.Parent = parent
	return sound
end

-- Initialize audio for bike
function AudioManager:AttachToBike(bike)
	self:DetachFromBike()
	currentBike = bike
	
	if not bike then return end
	
	-- Find audio attachment point (exhaust or main body)
	local audioParent = bike:FindFirstChild("DriveSeat", true) or bike.PrimaryPart or bike:FindFirstChildWhichIsA("BasePart")
	
	if not audioParent then
		warn("[AudioManager] No suitable parent for audio")
		return
	end
	
	-- Create engine sound (looped)
	if SoundConfig.Engine.Enabled then
		sounds.EngineIdle = createSound("EngineIdle", SoundConfig.Engine.IdleSound, audioParent, {
			Volume = SoundConfig.Engine.IdleVolume * SoundConfig.Engine.MasterVolume,
			Looped = true,
			PlaybackSpeed = 1,
			RollOffMode = "Linear",
			RollOffMaxDistance = 100,
			RollOffMinDistance = 10
		})
		
		sounds.EngineRev = createSound("EngineRev", SoundConfig.Engine.MidRPMSound, audioParent, {
			Volume = 0,
			Looped = true,
			PlaybackSpeed = 1,
			RollOffMode = "Linear",
			RollOffMaxDistance = 150,
			RollOffMinDistance = 15
		})
		
		-- Start engine sounds
		sounds.EngineIdle:Play()
		sounds.EngineRev:Play()
	end
	
	-- Create transmission sounds (one-shot)
	if SoundConfig.Transmission.Enabled then
		sounds.ShiftUp = createSound("ShiftUp", SoundConfig.Transmission.ShiftUpSound, audioParent, {
			Volume = SoundConfig.Transmission.Volume,
			Looped = false,
			RollOffMode = "Linear",
			RollOffMaxDistance = 80,
			RollOffMinDistance = 10
		})
		
		sounds.ShiftDown = createSound("ShiftDown", SoundConfig.Transmission.ShiftDownSound, audioParent, {
			Volume = SoundConfig.Transmission.Volume,
			Looped = false,
			RollOffMode = "Linear",
			RollOffMaxDistance = 80,
			RollOffMinDistance = 10
		})
	end
	
	-- Create tire sounds
	if SoundConfig.Tires.Enabled then
		sounds.TireSqueal = createSound("TireSqueal", SoundConfig.Tires.SquealSound, audioParent, {
			Volume = 0,
			Looped = true,
			PlaybackSpeed = 1,
			RollOffMode = "Linear",
			RollOffMaxDistance = 60,
			RollOffMinDistance = 5
		})
		sounds.TireSqueal:Play()
	end
	
	-- Create wind sound
	if SoundConfig.Ambient.Enabled then
		sounds.Wind = createSound("Wind", SoundConfig.Ambient.WindSound, audioParent, {
			Volume = SoundConfig.Ambient.MinWindVolume,
			Looped = true,
			PlaybackSpeed = 1,
			RollOffMode = "Linear",
			RollOffMaxDistance = 50,
			RollOffMinDistance = 0
		})
		sounds.Wind:Play()
	end
	
	if Logger then
		Logger.Info("Audio", "Attached", { bike = bike.Name, soundCount = #sounds })
	end
end

-- Cleanup audio
function AudioManager:DetachFromBike()
	for name, sound in pairs(sounds) do
		if sound and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	sounds = {}
	currentBike = nil
end

-- Update audio based on telemetry
function AudioManager:UpdateAudio(telemetry)
	if not self.Enabled or not currentBike then return end
	
	lastTelemetryTime = os.clock()
	
	local rpm = telemetry.rpm or telemetry.engineRpm or 0
	local speed = telemetry.speed or 0 -- km/h
	local gear = telemetry.gear or "N"
	local throttle = telemetry.throttle or 0
	
	-- Update engine sound
	if sounds.EngineIdle and sounds.EngineRev and SoundConfig.Engine.Enabled then
		-- Calculate RPM percentage
		local rpmPercent = math.clamp(rpm / 13000, 0, 1) -- Assuming 13000 max RPM
		
		-- Crossfade between idle and rev sounds
		local revVolume = math.clamp(rpmPercent * SoundConfig.Engine.RevVolume, 0, SoundConfig.Engine.RevVolume)
		local idleVolume = math.clamp((1 - rpmPercent) * SoundConfig.Engine.IdleVolume, 0, SoundConfig.Engine.IdleVolume)
		
		sounds.EngineIdle.Volume = idleVolume * SoundConfig.Engine.MasterVolume * self.MasterVolume
		sounds.EngineRev.Volume = revVolume * SoundConfig.Engine.MasterVolume * self.MasterVolume
		
		-- Adjust pitch based on RPM
		local pitchRange = SoundConfig.Engine.MaxPitch - SoundConfig.Engine.MinPitch
		local targetPitch = SoundConfig.Engine.MinPitch + (pitchRange * rpmPercent)
		
		sounds.EngineIdle.PlaybackSpeed = targetPitch
		sounds.EngineRev.PlaybackSpeed = targetPitch
	end
	
	-- Detect gear shifts
	if gear ~= lastGear and sounds.ShiftUp and SoundConfig.Transmission.Enabled then
		-- Determine if upshift or downshift
		local isUpshift = false
		if type(gear) == "number" and type(lastGear) == "number" then
			isUpshift = gear > lastGear
		end
		
		if isUpshift and sounds.ShiftUp then
			sounds.ShiftUp:Play()
		elseif sounds.ShiftDown then
			sounds.ShiftDown:Play()
		end
		
		if Logger then
			Logger.Info("Audio", "Shift", { from = lastGear, to = gear, up = isUpshift })
		end
	end
	
	-- Update tire squeal (based on speed and turning - simplified here)
	if sounds.TireSqueal and SoundConfig.Tires.Enabled then
		-- Simple logic: play squeal during hard acceleration or braking
		local speedChange = math.abs(speed - lastSpeed)
		local squealIntensity = math.clamp(speedChange / 10, 0, 1)
		
		if squealIntensity > 0.2 then
			sounds.TireSqueal.Volume = squealIntensity * SoundConfig.Tires.MaxVolume * self.MasterVolume
		else
			sounds.TireSqueal.Volume = 0
		end
	end
	
	-- Update wind sound based on speed
	if sounds.Wind and SoundConfig.Ambient.Enabled then
		local config = SoundConfig.Ambient
		if speed >= config.WindStartSpeed then
			local windProgress = math.clamp((speed - config.WindStartSpeed) / 150, 0, 1)
			sounds.Wind.Volume = config.MinWindVolume + (config.MaxWindVolume - config.MinWindVolume) * windProgress
			sounds.Wind.PlaybackSpeed = 0.8 + windProgress * 0.4 -- Pitch shift with speed
		else
			sounds.Wind.Volume = 0
		end
	end
	
	-- Store last values
	lastRPM = rpm
	lastSpeed = speed
	lastGear = gear
end

-- Connect to telemetry
local function connectTelemetry()
	local playerGui = player:WaitForChild("PlayerGui")
	
	local function bindEvent(evt)
		if evt and evt:IsA("BindableEvent") then
			evt.Event:Connect(function(data)
				AudioManager:UpdateAudio(data)
			end)
			if Logger then
				Logger.Info("Audio", "TelemetryConnected")
			end
		end
	end
	
	-- Look for existing event
	local telemetryEvent = playerGui:FindFirstChild("HelmetTelemetry")
	if telemetryEvent then
		bindEvent(telemetryEvent)
	end
	
	-- Watch for new events
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
		AudioManager:AttachToBike(bike)
	else
		currentSeat = nil
		AudioManager:DetachFromBike()
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

-- Fallback update (if telemetry fails)
RunService.Heartbeat:Connect(function()
	if currentSeat and (os.clock() - lastTelemetryTime) > 1 then
		-- Use seat data as fallback
		local speed = currentSeat.AssemblyLinearVelocity.Magnitude * 3.6
		AudioManager:UpdateAudio({
			rpm = lastRPM * 0.95, -- Decay RPM slowly
			speed = speed,
			gear = lastGear,
			throttle = currentSeat.Throttle
		})
	end
end)

print("✓ Audio Manager initialized")

return AudioManager
