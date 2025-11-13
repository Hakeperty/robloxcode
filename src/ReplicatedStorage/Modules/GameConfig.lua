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

return GameConfig
