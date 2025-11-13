-- GameConfig.lua
-- Shared configuration for the bike game

local GameConfig = {}

-- Game Settings
GameConfig.GameName = "Bike Racing Game"
GameConfig.Version = "1.0.0"

-- Bike Settings
GameConfig.Bike = {
	DefaultSpeed = 50,
	MaxSpeed = 100,
	TurnSpeed = 5,
	JumpPower = 50,
	BrakeForce = 20
}

-- Player Settings
GameConfig.Player = {
	StartingCoins = 100,
	RespawnTime = 5
}

-- Map Settings
GameConfig.Map = {
	Gravity = 196.2,
	DayLength = 600, -- seconds
	NightLength = 300 -- seconds
}

-- Economy
GameConfig.Economy = {
	CoinPerMeter = 1,
	TrickBonus = 10,
	RaceWinBonus = 500
}

--[[Dependencies]]

	local Burnout
	local success, err = pcall(function()
		Burnout = require(game.ReplicatedStorage.Burnout)
	end)
	if not success then
		warn("Burnout.lua not found, burnout effects will be disabled. Error: "..tostring(err))
	end

	local player = game.Players.LocalPlayer
	local UserInputService = game:GetService("UserInputService")
	local car = script.Parent.Car.Value
	local _Tune = require(car.Tuner)

--[[Burnout Effect]]
	local burnoutEffect
	if Burnout and _Tune.BurnoutEnabled then
		burnoutEffect = Burnout.new(car)
	end

--[[Output Scaling Factor]]
	local function UpdateOutputScaling()
		local scale = math.clamp(car.DriveSeat.Velocity.Magnitude / GameConfig.Bike.MaxSpeed, 0, 1)
		script.Parent.Values.OutputScale.Value = scale
	end

--[[Main Loop]]
	while true do
		wait(0.066) -- ~15 times per second

		-- Update External Values
		_IsOn = script.Parent.IsOn.Value
		_fABSActive = script.Parent.Values.ABSActive.Value
		_rABSActive = script.Parent.Values.ABSActiveRear.Value
		_MSteer = script.Parent.Values.MouseSteerOn.Value
		_GThrot = script.Parent.Values.Throttle.Value
		_GBrake = script.Parent.Values.Brake.Value
		wDia = car.WheelDiameter.Value

		-- Update Outputs
		script.Parent.Values.ABSActive.Value = _fABSActive or _rABSActive
		script.Parent.Values.MouseSteerOn.Value = _MSteer
		script.Parent.Values.Velocity.Value = car.DriveSeat.Velocity

		-- Burnout Effect Update
		if burnoutEffect then
			local isBurnout = (_GThrot > 0.8 and _GBrake > 0.8 and car.DriveSeat.Velocity.Magnitude < 10)
			local wheelSlip = (math.abs(Rear.Wheel.RotVelocity.Magnitude*(wDia/2) - Rear.Wheel.Velocity.Magnitude))
			burnoutEffect:Update(isBurnout, wheelSlip, _GThrot)
		end

		if _TMode == "Auto" then Auto() end
	end
	--]]
--[[END]]

return GameConfig
