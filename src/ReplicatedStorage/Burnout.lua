-- Burnout Effect Handler

local Burnout = {}

local Debris = game:GetService("Debris")

function Burnout.new(bike)
	local self = setmetatable({}, {__index = Burnout})
	
	self.Bike = bike
	self.Drive = require(bike.Scripts.Drive)
	self.Tune = self.Drive.Tune
	
	self.SmokePart = bike.Body.RLight -- Default part for smoke, can be changed
	if not self.SmokePart then
		self.SmokePart = bike.Body.R -- Fallback to rear wheel
	end

	self.Smoke = script.Smoke:Clone()
	self.Smoke.Parent = self.SmokePart
	
	self.Sparks = script.Sparks:Clone()
	self.Sparks.Parent = self.SmokePart

	self.Drive:GetPropertyChangedSignal("State"):Connect(function()
		self:Update()
	end)
	
	self:Update()
	
	return self
end

function Burnout:Update()
	local state = self.Drive:GetState()
	
	if state.IsBurnout then
		local slip = math.abs(state.WheelSpeed - state.GroundSpeed)
		local rate = math.clamp(slip / 50, 50, 200)
		self.Smoke.Rate = rate
		self.Sparks.Rate = rate / 4
		self.Smoke.Enabled = true
		self.Sparks.Enabled = true
	else
		self.Smoke.Enabled = false
		self.Sparks.Enabled = false
	end
end

-- Create particle effects if they don't exist
if not script:FindFirstChild("Smoke") then
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxassetid://179995382"
	smoke.Color = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(1, 1, 1))
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 3),
		NumberSequenceKeypoint.new(1, 8)
	})
	smoke.Lifetime = NumberRange.new(1, 2)
	smoke.Speed = NumberRange.new(5, 10)
	smoke.SpreadAngle = Vector2.new(30, 30)
	smoke.Rotation = NumberRange.new(-360, 360)
	smoke.RotSpeed = NumberRange.new(-180, 180)
	smoke.Rate = 100
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
	sparks.Rate = 25
	sparks.Enabled = false
	sparks.Parent = script
end


return Burnout
