-- SoundConfig.lua
-- Audio configuration for realistic motorcycle sounds

local SoundConfig = {}

-- Engine Audio
SoundConfig.Engine = {
	Enabled = true,
	
	-- Engine sound IDs (these would need to be actual Roblox audio asset IDs)
	IdleSound = "rbxassetid://0", -- Placeholder - needs actual asset ID
	LowRPMSound = "rbxassetid://0",
	MidRPMSound = "rbxassetid://0",
	HighRPMSound = "rbxassetid://0",
	RedlineSound = "rbxassetid://0",
	
	-- Volume settings (0-1)
	MasterVolume = 0.7,
	IdleVolume = 0.3,
	RevVolume = 0.8,
	
	-- Pitch settings (simulate RPM changes)
	MinPitch = 0.6,
	MaxPitch = 2.0,
	
	-- Crossfade between different engine sounds
	CrossfadeSpeed = 0.15,
}

-- Transmission Audio
SoundConfig.Transmission = {
	Enabled = true,
	
	-- Shift sounds
	ShiftUpSound = "rbxassetid://0",
	ShiftDownSound = "rbxassetid://0",
	ClutchSound = "rbxassetid://0",
	
	Volume = 0.5,
	
	-- Quick shifter (no clutch shift)
	QuickShiftSound = "rbxassetid://0",
	QuickShiftVolume = 0.6,
}

-- Exhaust Audio
SoundConfig.Exhaust = {
	Enabled = true,
	
	-- Exhaust sounds
	BackfireSound = "rbxassetid://0", -- Exhaust pop on decel
	ExhaustNote = "rbxassetid://0", -- Main exhaust tone
	
	-- Backfire settings
	BackfireChance = 0.3, -- 30% chance on aggressive downshift
	BackfireVolume = 0.6,
	
	Volume = 0.7,
}

-- Tire Audio
SoundConfig.Tires = {
	Enabled = true,
	
	-- Tire sounds
	SquealSound = "rbxassetid://0", -- Tire sliding
	SkidSound = "rbxassetid://0", -- Hard braking
	RollSound = "rbxassetid://0", -- Rolling noise
	
	-- Volume based on slip
	MinVolume = 0.1,
	MaxVolume = 0.7,
	
	-- Pitch changes with speed
	MinPitch = 0.8,
	MaxPitch = 1.3,
}

-- Braking Audio
SoundConfig.Brakes = {
	Enabled = true,
	
	-- Brake sounds
	BrakeSquealSound = "rbxassetid://0",
	ABSSound = "rbxassetid://0",
	
	Volume = 0.4,
}

-- Ambient Audio
SoundConfig.Ambient = {
	Enabled = true,
	
	-- Wind noise increases with speed
	WindSound = "rbxassetid://0",
	MinWindVolume = 0.0,
	MaxWindVolume = 0.5,
	WindStartSpeed = 20, -- km/h when wind starts
	
	-- Chain noise
	ChainSound = "rbxassetid://0",
	ChainVolume = 0.2,
}

-- Collision Audio
SoundConfig.Collision = {
	Enabled = true,
	
	-- Impact sounds
	LightImpact = "rbxassetid://0",
	MediumImpact = "rbxassetid://0",
	HeavyImpact = "rbxassetid://0",
	
	-- Scraping sounds
	ScrapeSound = "rbxassetid://0",
	
	Volume = 0.6,
	
	-- Minimum impact velocity to trigger sound
	MinImpactVelocity = 5, -- studs per second
}

-- Suspension Audio
SoundConfig.Suspension = {
	Enabled = true,
	
	-- Suspension sounds
	BottomOutSound = "rbxassetid://0", -- Suspension compression max
	ReboundSound = "rbxassetid://0",
	
	Volume = 0.3,
}

-- UI Audio
SoundConfig.UI = {
	Enabled = true,
	
	-- Menu sounds
	ButtonClick = "rbxassetid://0",
	ButtonHover = "rbxassetid://0",
	MenuOpen = "rbxassetid://0",
	MenuClose = "rbxassetid://0",
	
	-- Notification sounds
	Achievement = "rbxassetid://0",
	Warning = "rbxassetid://0",
	Countdown = "rbxassetid://0",
	
	Volume = 0.5,
}

-- Distance-based volume attenuation
SoundConfig.Attenuation = {
	-- How sound fades with distance
	RolloffMode = "Linear", -- Linear or InverseTapered
	MaxDistance = 100, -- studs
	MinDistance = 10, -- studs
}

-- Doppler effect (pitch shift based on relative velocity)
SoundConfig.Doppler = {
	Enabled = true,
	Scale = 0.5, -- How strong the doppler effect is
}

-- Master audio settings
SoundConfig.Master = {
	MasterVolume = 1.0,
	
	-- Audio categories for separate volume control
	Categories = {
		Engine = 1.0,
		Effects = 1.0,
		Ambient = 0.8,
		UI = 0.9,
		Music = 0.6,
	},
	
	-- Mute all sounds
	MuteAll = false,
}

return SoundConfig
