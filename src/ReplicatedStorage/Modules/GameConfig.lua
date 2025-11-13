-- GameConfig.lua
-- Shared configuration for the bike game
-- Based on 2008 Honda CBR1000RR Fireblade specifications

local GameConfig = {}

-- Game Settings
GameConfig.GameName = "MOTO MADNESS"
GameConfig.Version = "1.1.0"
GameConfig.Subtitle = "THE ULTIMATE RIDING EXPERIENCE"

-- Honda CBR1000RR Fireblade (2008) Real Specifications
GameConfig.Bike = {
	-- Physics (realistic values for Honda CBR1000RR)
	DefaultSpeed = 50,
	MaxSpeed = 299, -- km/h (actual top speed ~186 mph / 299 km/h)
	TopSpeedMPH = 186,
	Acceleration0to60 = 2.9, -- seconds (0-60 mph)
	Acceleration0to100 = 5.7, -- seconds (0-100 km/h)
	
	-- Engine Specs
	Engine = {
		Displacement = 999, -- cc
		Power = 178, -- bhp at 12,000 rpm
		Torque = 112, -- Nm at 8,500 rpm
		RedlineRPM = 13000,
		IdleRPM = 1300,
		MaxRPM = 13800,
		Cylinders = 4,
		Configuration = "Inline-4"
	},
	
	-- Weight and Balance
	Weight = 199, -- kg (dry weight)
	WeightDistribution = 52, -- % front / 48% rear
	
	-- Braking
	BrakeForce = 85, -- Realistic braking force
	FrontBrake = 60, -- % braking power
	RearBrake = 40, -- % braking power
	ABSEnabled = true,
	
	-- Handling
	TurnSpeed = 8, -- Responsive steering
	LeanAngle = 58, -- degrees (maximum lean angle)
	WheelBase = 1.41, -- meters
	SeatHeight = 0.82, -- meters
	
	-- Transmission
	Gears = 6,
	GearRatios = {2.286, 1.778, 1.500, 1.333, 1.214, 1.130},
	FinalDrive = 2.625, -- (42/16 sprockets)
	
	-- Visual Effects
	EnableSpeedLines = true,
	EnableMotionBlur = true,
	EnableCameraShake = true,
	FOVBoost = true, -- Increase FOV at high speed
	
	-- Audio
	EngineSound = true,
	ExhaustPop = true, -- Exhaust pops on deceleration
	TireSqueal = true,
	WindNoise = true,
}

-- Player Settings
GameConfig.Player = {
	StartingCoins = 500,
	RespawnTime = 3, -- Faster respawn for better gameplay
	EnableHelmetCam = true, -- First-person helmet camera
	EnableHUD = true,
	ShowSpeedometer = true,
	ShowRPM = true,
	ShowGear = true,
}

-- Map Settings
GameConfig.Map = {
	Gravity = 196.2, -- Roblox studs/s² (default realistic)
	DayLength = 480, -- 8 minutes (more dynamic)
	NightLength = 240, -- 4 minutes
	
	-- Weather System
	DynamicWeather = true,
	RainEnabled = true,
	WindEnabled = true,
	TimeOfDayEffects = true,
}

-- Economy
GameConfig.Economy = {
	CoinPerMeter = 0.5, -- Balanced earning
	SpeedBonus = 2, -- Bonus multiplier for high speed
	DriftBonus = 10, -- Bonus for drifting
	WheelieBonus = 15, -- Bonus for wheelies
	JumpBonus = 20, -- Bonus for jumps
	NearMissBonus = 25, -- Bonus for near misses
	RaceWinBonus = 1000,
	PerfectShiftBonus = 5, -- Bonus for perfect shifts
}

-- Performance Settings
GameConfig.Performance = {
	-- Graphics quality affects performance
	ParticleQuality = "High", -- High, Medium, Low
	ShadowQuality = "Medium",
	LightingQuality = "High",
	MotionBlurEnabled = true,
	DOFEnabled = false, -- Depth of field (performance cost)
}

-- Gameplay Settings
GameConfig.Gameplay = {
	DamageEnabled = false, -- No bike damage for now
	FuelSystem = false, -- No fuel management
	TireWear = true,
	RealismMode = "Arcade", -- Arcade, Simulation, or Hardcore
	
	-- Traffic and AI
	TrafficEnabled = false,
	AIRacers = false,
	
	-- Assists
	TractionControl = true,
	AntiWheelieControl = false, -- Allow wheelies
	StabilityControl = true,
	AutoTransmission = true, -- Can be toggled
}

-- UI Settings
GameConfig.UI = {
	MinimapEnabled = false,
	SpeedUnit = "KMH", -- KMH or MPH
	ShowFPS = false,
	ShowPing = false,
	ChatEnabled = true,
	
	-- HUD Colors
	PrimaryColor = Color3.fromRGB(255, 70, 50),
	SecondaryColor = Color3.fromRGB(0, 122, 255),
	SuccessColor = Color3.fromRGB(50, 200, 50),
	WarningColor = Color3.fromRGB(255, 180, 0),
	DangerColor = Color3.fromRGB(255, 50, 50),
}

return GameConfig
