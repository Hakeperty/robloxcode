-- luacheck: globals game Enum Instance Vector3 Vector2 Color3 NumberRange NumberSequence NumberSequenceKeypoint RaycastParams typeof script workspace
-- Burnout Effect Handler (bike-agnostic)

local Burnout = {}
local Logger
local ReplicatedStorage = game:GetService("ReplicatedStorage")
pcall(function()
	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	if Modules then
		Logger = require(Modules:FindFirstChild("ClientLogger"))
	end
end)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Material = Enum.Material
local ActuatorRelativeTo = Enum.ActuatorRelativeTo

local DEFAULT_SURFACE_PROFILE = { grip = 0.85, sparks = true }
local SURFACE_PROFILES = {
	[Material.Asphalt] = { grip = 0.9, sparks = true },
	[Material.Concrete] = { grip = 0.95, sparks = true },
	[Material.Cobblestone] = { grip = 0.82, sparks = true },
	[Material.Metal] = { grip = 0.88, sparks = true },
	[Material.Rock] = { grip = 0.8, sparks = true },
	[Material.Slate] = { grip = 0.83, sparks = true },
	[Material.Glass] = { grip = 0.55, sparks = false },
	[Material.Ice] = { grip = 0.4, sparks = false },
	[Material.Snow] = { grip = 0.5, sparks = false },
	[Material.Mud] = { grip = 0.45, sparks = false },
	[Material.Sand] = { grip = 0.48, sparks = false },
	[Material.Grass] = { grip = 0.6, sparks = false },
	[Material.LeafyGrass] = { grip = 0.62, sparks = false },
	[Material.Ground] = { grip = 0.65, sparks = false },
	[Material.Plastic] = { grip = 0.75, sparks = true }
}

local function determineWheelGeometry(part)
	local size = part.Size
	local axes = {
		{ axis = Vector3.new(1, 0, 0), length = size.X },
		{ axis = Vector3.new(0, 1, 0), length = size.Y },
		{ axis = Vector3.new(0, 0, 1), length = size.Z }
	}
	table.sort(axes, function(a, b)
		return a.length < b.length
	end)
	local localAxis = axes[1].axis
	local radius = math.max(axes[2].length, axes[3].length) * 0.5
	if radius < 0.2 then radius = 0.35 end
	return localAxis, radius
end

local function getWorldCFrame(inst)
	if not inst then return nil end
	if inst:IsA("Attachment") then
		return inst.WorldCFrame
	end
	if inst:IsA("BasePart") then
		return inst.CFrame
	end
	if inst:IsA("Model") and inst.GetPivot then
		local ok, cf = pcall(function()
			return inst:GetPivot()
		end)
		if ok then
			return cf
		end
	end
	return nil
end

local function getWorldPosition(inst)
	if not inst then return nil end
	if inst:IsA("Attachment") then
		return inst.WorldPosition
	end
	if inst:IsA("BasePart") then
		return inst.Position
	end
	local cf = getWorldCFrame(inst)
	return cf and cf.Position or nil
end

local function findVehicleSeat(model)
	return model:FindFirstChildWhichIsA("VehicleSeat", true)
end

local function findRearWheelPart(model)
	-- Try common naming for rear wheel/axle
	local candidates = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local n = d.Name:lower()
			if n == "r" or n:find("rear") or n:find("back") or n:find("rwheel") or n:find("rearwheel") or n:find("backwheel") then
				table.insert(candidates, d)
			end
		end
	end
	if #candidates > 0 then
		table.sort(candidates, function(a, b)
			return a.Size.Magnitude > b.Size.Magnitude
		end)
		return candidates[1]
	end
	-- Fallback to any wheel-like part (circular-ish)
	local best, bestScore
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local size = d.Size
			local score = math.abs(size.X - size.Z)
			if not best or score < bestScore then
				best, bestScore = d, score
			end
		end
	end
	return best or model.PrimaryPart
end

function Burnout.new(bike)
	local self = setmetatable({}, { __index = Burnout })
	self.Bike = bike
	self.Seat = findVehicleSeat(bike)
	self.RefPart = (self.Seat and self.Seat:IsA("BasePart") and self.Seat) or bike.PrimaryPart or findRearWheelPart(bike)
	self.AttachPart = findRearWheelPart(bike) or self.RefPart
	self.RequireSpacebar = true
	self.SpacePressed = false
	self.RequireFirstGear = true
	self._drive = nil
	self.HoldAttachment = nil
	self.HoldLV = nil
	self.HoldAV = nil
	self._lastHoldActive = false
	self._smoothedFactor = 0
	self._smokeRate = 0
	self._sparkRate = 0
	self._lastUpdateTime = os.clock()
	self._surfaceProfile = DEFAULT_SURFACE_PROFILE
	self._surfaceMaterial = Material.Asphalt
	self._surfaceNormal = Vector3.new(0, 1, 0)
	self._lastSurfaceProbe = 0
	self._rayParams = nil
	self._rainIntensity = 0
	self._lastSlip = 0
	self._localWheelAxis, self._wheelRadius = determineWheelGeometry(self.AttachPart)

	-- Try to get Drive state if present for gear detection
	local ok, drv = pcall(function()
		local scriptsFolder = bike:FindFirstChild("Scripts")
		if scriptsFolder then
			local d = scriptsFolder:FindFirstChild("Drive")
			if d then
				return require(d)
			end
		end
		return nil
	end)
	if ok and type(drv) == "table" and type(drv.GetState) == "function" then
		self._drive = drv
	end

	-- Build particle templates on first use
	if not script:FindFirstChild("Smoke") then
		local smoke = Instance.new("ParticleEmitter")
		smoke.Name = "Smoke"
		smoke.Texture = "rbxassetid://179995382"
		smoke.Color = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(1, 1, 1))
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.78),
			NumberSequenceKeypoint.new(1, 1)
		})
		smoke.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.2),
			NumberSequenceKeypoint.new(0.2, 3.5),
			NumberSequenceKeypoint.new(1, 9.5)
		})
		smoke.Lifetime = NumberRange.new(1.4, 2.6)
		smoke.Speed = NumberRange.new(5, 10)
		smoke.SpreadAngle = Vector2.new(30, 30)
		smoke.Rotation = NumberRange.new(-360, 360)
		smoke.RotSpeed = NumberRange.new(-180, 180)
		smoke.Rate = 0
		smoke.Enabled = false
		smoke.Parent = script
	end
	if not script:FindFirstChild("Sparks") then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "Sparks"
		sparks.Texture = "rbxassetid://212775344"
		sparks.Color = ColorSequence.new(Color3.new(1, 0.66, 0.25), Color3.new(1, 1, 0.5))
		sparks.LightEmission = 1
		sparks.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		sparks.Size = NumberSequence.new(0.2, 0.5)
		sparks.Lifetime = NumberRange.new(0.1, 0.5)
		sparks.Speed = NumberRange.new(20, 40)
		sparks.SpreadAngle = Vector2.new(25, 25)
		sparks.Rate = 0
		sparks.Enabled = false
		sparks.Parent = script
	end

	-- Clone emitters onto attach part
	self.Smoke = script.Smoke:Clone()
	self.Sparks = script.Sparks:Clone()
	self.Smoke.Parent = self.AttachPart
	self.Sparks.Parent = self.AttachPart

	-- Prepare a zero-velocity LinearVelocity for anchoring during burnout
	local att = Instance.new("Attachment")
	att.Name = "BurnoutHoldAttachment"
	att.Parent = self.AttachPart
	self.HoldAttachment = att

	local lv = Instance.new("LinearVelocity")
	lv.Name = "BurnoutHold"
	lv.Attachment0 = att
	lv.RelativeTo = ActuatorRelativeTo.World
	lv.VectorVelocity = Vector3.new(0, 0, 0)
	lv.MaxForce = 0 -- disabled by default
	lv.Enabled = false
	lv.Parent = self.AttachPart
	self.HoldLV = lv

	-- Prepare an AngularVelocity for rotational locking during burnout
	local av = Instance.new("AngularVelocity")
	av.Name = "BurnoutAngularHold"
	av.Attachment0 = att
	av.RelativeTo = ActuatorRelativeTo.World
	av.AngularVelocity = Vector3.new(0, 0, 0)
	av.MaxTorque = 0 -- disabled by default
	av.Enabled = false
	av.Parent = self.AttachPart
	self.HoldAV = av

	self._rayParams = RaycastParams.new()
	self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
	self._rayParams.FilterDescendantsInstances = { self.Bike }

	-- Update loop (client)
	self._conn = RunService.RenderStepped:Connect(function()
		self:Update()
	end)

	-- Initial state
	self:Update()
	return self
end

function Burnout:Destroy()
	if self._conn then self._conn:Disconnect() self._conn = nil end
	if self.Smoke then self.Smoke.Enabled = false self.Smoke:Destroy() end
	if self.Sparks then self.Sparks.Enabled = false self.Sparks:Destroy() end
	if self.HoldLV then self.HoldLV:Destroy() end
	if self.HoldAV then self.HoldAV:Destroy() end
	if self.HoldAttachment then self.HoldAttachment:Destroy() end
end

function Burnout:SetSpacePressed(pressed)
	self.SpacePressed = not not pressed
end

function Burnout:_getThrottle()
	local seat = self.Seat
	if seat and seat:IsA("VehicleSeat") then
		-- Throttle is -1,0,1; approximate float
		local t = seat.Throttle or 0
		if t > 0 then return 1 elseif t < 0 then return 0.5 else return 0 end
	end
	return 0
end

function Burnout:_getSpeed()
	local ref = self.RefPart
	if ref and ref.Parent then
		return ref.AssemblyLinearVelocity.Magnitude
	end
	return 0
end

function Burnout:_isFirstGear()
	if not self.RequireFirstGear then return true end
	local d = self._drive
	if d then
		local ok, state = pcall(function() return d:GetState() end)
		if ok and typeof(state) == "table" then
			local g = state.Gear or state.gear or state.CurrentGear
			if typeof(g) == "number" then
				return g == 1
			end
			if typeof(g) == "string" then
				return g == "1" or g:lower() == "first"
			end
		end
	end
	-- Fallback heuristic: nearly stationary implies likely low gear
	return self:_getSpeed() < 6
end

function Burnout:Update()
	if not self.AttachPart or not self.AttachPart.Parent then
		return
	end

	local now = os.clock()
	local dt = math.clamp(now - (self._lastUpdateTime or now), 0, 0.2)
	self._lastUpdateTime = now

	local throttle = self:_getThrottle()
	local speed = self:_getSpeed()
	local gearOK = self:_isFirstGear()
	local spaceOK = (not self.RequireSpacebar) or self.SpacePressed
	local attachCFrame = getWorldCFrame(self.AttachPart)
	if not attachCFrame then
		return
	end
	local attachUp = attachCFrame.UpVector
	local basePart = self.AttachPart
	if not basePart:IsA("BasePart") and basePart.Parent and basePart.Parent:IsA("BasePart") then
		basePart = basePart.Parent
	end

	if now - (self._lastSurfaceProbe or 0) > 0.2 then
		self._lastSurfaceProbe = now
		local origin = getWorldPosition(self.AttachPart)
		if origin then
			local direction = -attachUp * (self._wheelRadius + 3)
			local result = Workspace:Raycast(origin + attachUp * 0.15, direction, self._rayParams)
			if result then
				self._surfaceMaterial = result.Material
				self._surfaceNormal = result.Normal
				local profile = SURFACE_PROFILES[self._surfaceMaterial]
				if profile then
					self._surfaceProfile = profile
				else
					self._surfaceProfile = DEFAULT_SURFACE_PROFILE
				end
			end
		end
	end

	local rainAttr = ReplicatedStorage:GetAttribute("RainIntensity")
	if typeof(rainAttr) == "number" then
		self._rainIntensity = math.clamp(rainAttr, 0, 1)
	else
		self._rainIntensity = 0
	end

	local localAxis = self._localWheelAxis
	local axisWorld = attachCFrame:VectorToWorldSpace(localAxis)
	local angular = Vector3.new(0, 0, 0)
	if basePart and basePart:IsA("BasePart") then
		angular = basePart.AssemblyAngularVelocity
	end
	local wheelLinearSpeed = math.abs(angular:Dot(axisWorld)) * self._wheelRadius
	local slipSpeed = math.max(0, wheelLinearSpeed - speed)
	self._lastSlip = slipSpeed


	local grip = self._surfaceProfile and self._surfaceProfile.grip or DEFAULT_SURFACE_PROFILE.grip
	local wetGrip = grip * (1 - 0.55 * self._rainIntensity)
	local slipAmplifier = math.clamp(1.1 / math.max(0.3, wetGrip), 0.85, 2.4)
	local baseSlipFactor = 0
	if wheelLinearSpeed > 0.1 then
		local denom = math.max(speed, 6)
		baseSlipFactor = math.clamp(slipSpeed / denom, 0, 1.5)
	end

	local burnoutTarget = 0
	if spaceOK and gearOK and throttle > 0 then
		burnoutTarget = math.clamp(throttle * baseSlipFactor * slipAmplifier, 0, 1.25)
		if wheelLinearSpeed < speed * 0.9 then
			burnoutTarget = burnoutTarget * 0.6
		end
	end
	if spaceOK and throttle > 0.65 and speed < 5 then
		burnoutTarget = math.max(burnoutTarget, 0.25 + throttle * 0.35)
	end

	self._smoothedFactor = self._smoothedFactor + (burnoutTarget - self._smoothedFactor) * math.min(1, dt * 6)
	local burnoutFactor = math.clamp(self._smoothedFactor, 0, 1)

	-- Debug logging for troubleshooting (throttled to avoid spam)
	self._lastLogTime = self._lastLogTime or 0
	if Logger and spaceOK and (now - self._lastLogTime > 1.0) then -- Log every 1 second max
		self._lastLogTime = now
		Logger.Info("Burnout", "BurnoutCalc", { 
			throttle = throttle,
			speed = speed,
			wheelSpeed = wheelLinearSpeed,
			slipSpeed = slipSpeed,
			surface = tostring(self._surfaceMaterial),
			rain = self._rainIntensity,
			gearOK = gearOK,
			spaceOK = spaceOK,
			burnoutFactor = burnoutFactor
		})
	end

	local slipBoost = math.clamp(slipSpeed * 8, 0, 110)
	local smokeTarget = 25 + burnoutFactor * 170 + slipBoost
	local sparksTarget = smokeTarget * 0.28

	self._smokeRate = self._smokeRate + (smokeTarget - self._smokeRate) * math.min(1, dt * 4)
	self._sparkRate = self._sparkRate + (sparksTarget - self._sparkRate) * math.min(1, dt * 4)

	local smokeRate = math.max(0, self._smokeRate + (math.random() - 0.5) * 6)
	local sparksAllowed = (self._surfaceProfile and self._surfaceProfile.sparks) and slipSpeed > 1.5 and burnoutFactor > 0.25
	local sparkRate = sparksAllowed and math.max(0, self._sparkRate + (math.random() - 0.5) * 4) or 0

	self.Smoke.Rate = smokeRate
	self.Sparks.Rate = sparkRate
	local enabled = smokeRate > 3
	self.Smoke.Enabled = enabled
	self.Sparks.Enabled = sparkRate > 1

	local forward = (self.Seat and self.Seat.CFrame.LookVector) or attachCFrame.LookVector
	self.Smoke.Acceleration = forward * -(18 + 45 * burnoutFactor) + Vector3.new(0, 16 + 34 * burnoutFactor, 0)
	self.Sparks.Acceleration = forward * -(40 + 60 * burnoutFactor) + Vector3.new(0, 14, 0)
	self.Smoke.Speed = NumberRange.new(4 + burnoutFactor * 6, 10 + burnoutFactor * 12)
	self.Smoke.Lifetime = NumberRange.new(1 + burnoutFactor * 0.8, 2.4 + burnoutFactor * 1.4)
	self.Sparks.Lifetime = NumberRange.new(0.12 + burnoutFactor * 0.08, 0.28 + burnoutFactor * 0.18)
	self.Sparks.Size = NumberSequence.new(0.18 + burnoutFactor * 0.15, 0.48 + burnoutFactor * 0.22)

	-- Debug logging for particle state (throttled)
	if enabled and Logger and (now - (self._lastParticleLogTime or 0) > 2.0) then -- Log every 2 seconds max
		self._lastParticleLogTime = now
		Logger.Info("Burnout", "ParticleState", { 
			smokeRate = smokeRate, 
			sparksRate = sparkRate, 
			smokeEnabled = enabled, 
			sparksEnabled = self.Sparks.Enabled,
			throttle = throttle,
			speed = speed,
			wheelSpeed = wheelLinearSpeed,
			slipSpeed = slipSpeed,
			surface = tostring(self._surfaceMaterial),
			rain = self._rainIntensity,
			gearOK = gearOK,
			spaceOK = spaceOK,
			burnoutFactor = burnoutFactor
		})
	end

	-- Apply a strong hold to prevent translation and rotation while doing a burnout
	local shouldHold = enabled and (burnoutFactor > 0.3)
	if self.HoldLV and self.HoldAV then
		if shouldHold then
			local mass = 0
			local ok, m = pcall(function() return self.Bike:GetMass() end)
			if ok and type(m) == "number" then mass = m end
			-- Enough to counter typical engine forces without jitter
			self.HoldLV.MaxForce = math.max(5000 * mass, 1e5)
			-- Prevent rotation during burnout as well
			self.HoldAV.MaxTorque = math.max(3000 * mass, 5e4)
			if not self._lastHoldActive and Logger then
				Logger.Info("Burnout", "HoldStart", { factor = burnoutFactor, smokeRate = smokeRate, sparksRate = sparkRate })
			end
			self.HoldLV.Enabled = true
			self.HoldAV.Enabled = true
		else
			if self._lastHoldActive and Logger then
				Logger.Info("Burnout", "HoldEnd")
			end
			self.HoldLV.Enabled = false
			self.HoldLV.MaxForce = 0
			self.HoldAV.Enabled = false
			self.HoldAV.MaxTorque = 0
		end
	end
	self._lastHoldActive = shouldHold
end

-- Create particle effects if they don't exist
-- Note: particle templates are created in Burnout.new on first use

return Burnout
