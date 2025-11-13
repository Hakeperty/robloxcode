-- BikeVFX.client.lua
-- Client-side visual effects for motorcycle exhaust backfire and heat shimmer
-- Attaches to known exhaust attachments when the player is seated on a bike.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientLogger = require(ReplicatedStorage.Modules.ClientLogger)

local player = Players.LocalPlayer
local currentSeat = nil
local currentBike = nil
local exhaustAttachments = {}
local flameEmitters = {}
local smokeEmitters = {}
local telemetryConn = nil
local telemetryWatcher = nil
local lastTelemetryClock = 0
local driveModule = nil
local drivePollAccumulator = 0

local lastRpm = 0
local lastSpeed = 0
local lastThrottle = 0
local lastGear = "N"
local lastBackfireTime = 0

local EffectsActive = false

local function clampNumber(value, minValue, maxValue)
	if type(value) ~= "number" then
		return minValue
	end
	if value ~= value then
		return minValue
	end
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function findBikeFromSeat(seat)
	if not seat or not seat.Parent then return nil end
	-- Typically seat.Parent is the bike Model
	return seat.Parent
end

local function findExhaustAttachments(bike)
	local results = {}
	for _, inst in ipairs(bike:GetDescendants()) do
		if inst:IsA("Attachment") then
			local n = string.lower(inst.Name)
			if n == "exhaust" or n == "exhaustl" or n == "exhaustr" or n:find("exhaust") then
				table.insert(results, inst)
			end
		elseif inst:IsA("BasePart") then
			local pn = string.lower(inst.Name)
			if pn:find("exhaust") then
				-- Create a helper attachment on this part if none exists
				local existing = inst:FindFirstChildWhichIsA("Attachment")
				if existing then
					table.insert(results, existing)
				else
					local a = Instance.new("Attachment")
					a.Name = "ExhaustAuto"
					a.Parent = inst
					table.insert(results, a)
				end
			end
		end
	end
	return results
end

local function createEmittersOn(attach)
	-- Flame emitter (short-lived, bright)
	local flame = Instance.new("ParticleEmitter")
	flame.Name = "ExhaustFlame"
	flame.Enabled = false
	flame.Rate = 0
	flame.Lifetime = NumberRange.new(0.08, 0.16)
	flame.Speed = NumberRange.new(18, 30)
	flame.SpreadAngle = Vector2.new(6, 6)
	flame.Texture = "rbxassetid://24187691" -- small soft circle
	flame.Rotation = NumberRange.new(0, 360)
	flame.RotSpeed = NumberRange.new(-80, 80)
	flame.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 220, 120)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 160, 60)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 50, 10))
	})
	flame.LightEmission = 0.8
	flame.LightInfluence = 0
	flame.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.25),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(1.0, 0.15),
	})
	flame.Parent = attach

	-- Smoke emitter (longer-lived, grey)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "ExhaustSmoke"
	smoke.Enabled = false
	smoke.Rate = 0
	smoke.Lifetime = NumberRange.new(0.3, 0.6)
	smoke.Speed = NumberRange.new(6, 10)
	smoke.SpreadAngle = Vector2.new(10, 10)
	smoke.Texture = "rbxassetid://771221224" -- soft smoke puff
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(200, 200, 200)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(80, 80, 80)),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.2),
		NumberSequenceKeypoint.new(1.0, 0.9),
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.3),
		NumberSequenceKeypoint.new(1.0, 1.1),
	})
	smoke.Parent = attach

	table.insert(flameEmitters, flame)
	table.insert(smokeEmitters, smoke)
end

local function clearEmitters()
	for _, e in ipairs(flameEmitters) do
		if e and e.Parent then e:Destroy() end
	end
	for _, e in ipairs(smokeEmitters) do
		if e and e.Parent then e:Destroy() end
	end
	flameEmitters = {}
	smokeEmitters = {}
	exhaustAttachments = {}
	lastRpm = 0
	lastSpeed = 0
	lastThrottle = 0
	lastGear = "N"
end

local function attachToBike(bike)
	clearEmitters()
	exhaustAttachments = findExhaustAttachments(bike)
	for _, a in ipairs(exhaustAttachments) do
		createEmittersOn(a)
	end
	EffectsActive = #exhaustAttachments > 0
end

local function processTelemetry(data)
	-- The HUD now sends a richer telemetry packet. Let's use the more precise values if available.
	local speed = data.physicsSpeed or data.speed
	local rpmInstant = tonumber(data.rawRpm) or tonumber(data.rpm) or tonumber(data.estimatedRpm) or lastRpm or 0
	local throttleValue = data.seatThrottle or data.throttle or data.throttleInput or lastThrottle or 0
	local gear = data.gearIndex or data.gear
	
	lastTelemetryClock = os.clock()
	
	-- Log received data for debugging
	ClientLogger.Log(
		'VFX',
		'Telemetry',
		{
			speed = speed,
			rpm = rpmInstant,
			throttle = throttleValue,
			gear = gear,
			hasRaw = data.rawRpm ~= nil,
			hasSeatThrottle = data.seatThrottle ~= nil,
		}
	)

	if not EffectsActive then
		return
	end

	-- Tuner values - should be on the bike's Tuner object
	local minRpm = 800
	local maxRpm = 7000
	local minSpeed = 0
	local maxSpeed = 120

	local rpmRange = maxRpm - minRpm
	local speedRange = maxSpeed - minSpeed

	local function mapValue(value, inMin, inMax, outMin, outMax)
		return (value - inMin) / (inMax - inMin) * (outMax - outMin) + outMin
	end

	local mappedRpm = clampNumber(mapValue(rpmInstant, minRpm, maxRpm, 0, 1), 0, 1)
	local mappedSpeed = clampNumber(mapValue(speed, minSpeed, maxSpeed, 0, 1), 0, 1)

	-- Backfire logic
	local rpmDrop = lastRpm - rpmInstant
	local speedDrop = lastSpeed - speed
	local throttleChange = lastThrottle - throttleValue
	local gearChanged = gear ~= lastGear

	local shouldPop = false
	local intensity = 0.6
	local now = os.clock()

	if gearChanged and lastRpm > 5000 then
		shouldPop = true
		intensity = intensity + math.abs(rpmDrop) / 600
	elseif lastRpm > 6500 then
		if throttleValue < 0.25 and throttleChange > 0.35 and rpmDrop > 250 then
			shouldPop = true
			intensity = intensity + (throttleChange * 0.7) + (rpmDrop / 700)
		elseif rpmDrop > 450 then
			shouldPop = true
			intensity = intensity + rpmDrop / 650
		elseif speed < 7 and rpmDrop > 320 then
			shouldPop = true
			intensity = intensity + rpmDrop / 520
		end
	elseif lastRpm > 4200 and rpmDrop > 700 and speedDrop > -1 then
		shouldPop = true
		intensity = intensity + rpmDrop / 820
	end

	local minCooldown = gearChanged and 0.08 or 0.14
	if shouldPop and #flameEmitters > 0 and (now - lastBackfireTime) >= minCooldown then
		intensity = clampNumber(intensity, 0.4, 1.9)
		local flames = math.max(1, math.floor(intensity * 3 + 0.3))
		local smokes = math.max(2, math.floor(intensity * 6.5 + 0.5))
		for _, e in ipairs(flameEmitters) do
			e:Emit(flames)
		end
		for _, e in ipairs(smokeEmitters) do
			e:Emit(smokes)
		end
		lastBackfireTime = now
	elseif rpmInstant > 0 and rpmInstant < 1100 then
		for _, e in ipairs(smokeEmitters) do
			if math.random() < 0.12 then
				e:Emit(1)
			end
		end
	end

	-- Exhaust smoke logic
	if rpmInstant > 0 and rpmInstant < 1100 then
		-- idle
		for i, p in ipairs(smokeEmitters) do
			p.Enabled = true
			p.Rate = 5
		end
	elseif rpmInstant > 6000 then
		-- high revs
		for i, p in ipairs(smokeEmitters) do
			p.Enabled = true
			p.Rate = 20
		end
	else
		-- cruising
		for i, p in ipairs(smokeEmitters) do
			p.Enabled = false
		end
	end

	-- Update last values
	lastRpm = rpmInstant
	lastSpeed = speed
	lastThrottle = throttleValue
	lastGear = gear
end

local function connectSeat(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		local seat = humanoid.SeatPart
		currentSeat = seat and seat:IsA("VehicleSeat") and seat or nil
		currentBike = findBikeFromSeat(currentSeat)
		if currentBike then
			attachToBike(currentBike)
		else
			clearEmitters()
			EffectsActive = false
		end
	end)
end

-- Hook telemetry from Helmet/Motorcycle HUD
local function connectTelemetry()
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end

	local function bind(evt)
		if telemetryConn then
			telemetryConn:Disconnect()
			telemetryConn = nil
		end
		if evt and evt:IsA("BindableEvent") then
			telemetryConn = evt.Event:Connect(processTelemetry)
		end
	end

	local evt = pg:FindFirstChild("HelmetTelemetry")
	if evt and evt:IsA("BindableEvent") then
		bind(evt)
	end

	if not telemetryWatcher then
		telemetryWatcher = pg.ChildAdded:Connect(function(child)
			if child.Name == "HelmetTelemetry" and child:IsA("BindableEvent") then
				bind(child)
			end
		end)
	end
end

player.CharacterAdded:Connect(function(ch)
	connectSeat(ch)
	connectTelemetry()
end)

if player.Character then
	connectSeat(player.Character)
end
connectTelemetry()

RunService.RenderStepped:Connect(function(dt)
	-- Poll drivetrain state so backfire reacts even when HUD telemetry skips frames
	if driveModule then
		drivePollAccumulator = drivePollAccumulator + dt
		if drivePollAccumulator >= 0.05 then
			drivePollAccumulator = 0
			local ok, state = pcall(function()
				return driveModule:GetState()
			end)
			if ok and type(state) == "table" then
				processTelemetry({
					speed = state.Speed or state.VehicleSpeed or state.ForwardSpeed or state.ChassisSpeed or state.LinearSpeed,
					rpm = state.EngineRPM or state.EngineRpm or state.RPM or state.EngineSpeed,
					gear = state.Gear or state.CurrentGear or state.TransmissionGear,
					throttle = state.Throttle or state.ThrottleInput or state.ThrottleRatio or state.Accel or state.TargetThrottle or state.EngineThrottle,
				})
			end
		end
	elseif currentSeat and currentSeat:IsA("VehicleSeat") and (os.clock() - lastTelemetryClock) > 0.5 then
		-- Fallback: estimate telemetry from seat if UI hasn't emitted recently
		drivePollAccumulator = 0
		processTelemetry({
			speed = currentSeat.AssemblyLinearVelocity.Magnitude,
			gear = lastGear,
			rpm = lastRpm * 0.98,
			throttle = currentSeat.Throttle,
		})
	end
end)

RunService.Heartbeat:Connect(function()
	if currentSeat and not currentSeat.Parent then
		currentSeat = nil
		currentBike = nil
		clearEmitters()
	end
	
	local now = os.clock()
	if now - lastTelemetryClock > 5 then
		-- stale data; don't emit based on RPM, but provide minimal exhaust
		lastRpm = 0
		lastSpeed = 0
		
		-- Minimal continuous exhaust when on bike (simulate idle)
		if currentSeat and currentBike and #smokeEmitters > 0 then
			if math.random() < 0.02 then -- 2% chance per frame for idle puff
				local smokePuffs = 1
				for _, e in ipairs(smokeEmitters) do
					e:Emit(smokePuffs)
				end
			end
		end
	end
end)
