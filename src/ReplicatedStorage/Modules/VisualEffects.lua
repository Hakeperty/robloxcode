-- VisualEffects.lua
-- Configuration for visual effects to enhance realism

local VisualEffects = {}

-- Camera Effects
VisualEffects.Camera = {
	-- Field of View changes
	FOV = {
		Enabled = true,
		BaseFOV = 75, -- Default FOV
		MaxFOV = 90, -- Max FOV at high speed
		SpeedThreshold = 100, -- Speed (km/h) to reach max FOV
		TransitionSpeed = 0.1, -- How fast FOV changes
	},
	
	-- Camera shake for immersion
	Shake = {
		Enabled = true,
		
		-- Shake intensity based on speed
		SpeedShake = true,
		MaxShakeIntensity = 0.3,
		ShakeFrequency = 20, -- Hz
		
		-- Shake on rough terrain
		TerrainShake = true,
		
		-- Shake during impacts
		ImpactShake = true,
		ImpactShakeDecay = 0.5, -- How fast impact shake fades
	},
	
	-- Head bobbing while riding
	HeadBob = {
		Enabled = false, -- Can be distracting
		Intensity = 0.1,
		Frequency = 2, -- Hz
	},
	
	-- Lean camera with bike
	LeanWithBike = {
		Enabled = true,
		MaxLeanAngle = 10, -- degrees to tilt camera
		LeanSpeed = 0.2, -- How fast camera leans
	},
}

-- Speed Lines Effect
VisualEffects.SpeedLines = {
	Enabled = true,
	
	-- When to show speed lines
	MinSpeed = 80, -- km/h
	MaxSpeed = 200, -- km/h (full intensity)
	
	-- Visual properties
	Color = Color3.fromRGB(255, 255, 255),
	Transparency = 0.7,
	Length = 50, -- studs
	Width = 0.5,
	
	-- Animation
	SpawnRate = 10, -- lines per second at max speed
	Lifetime = 0.5, -- seconds
	FadeIn = 0.1,
	FadeOut = 0.2,
	
	-- Distribution
	Radius = 20, -- Spawn radius around player
	MinDistance = 10, -- Min distance from camera
}

-- Motion Blur
VisualEffects.MotionBlur = {
	Enabled = true,
	
	-- Blur intensity based on speed
	MinSpeed = 50, -- km/h to start blur
	MaxSpeed = 150, -- km/h for max blur
	
	-- Blur settings
	MaxBlurSize = 20, -- pixels
	Quality = "Medium", -- Low, Medium, High
	
	-- Directional blur (based on movement direction)
	DirectionalBlur = true,
}

-- Particles and Effects
VisualEffects.Particles = {
	-- Tire smoke during burnout
	TireSmoke = {
		Enabled = true,
		Color = Color3.fromRGB(200, 200, 200),
		Lifetime = NumberRange.new(2, 3),
		Rate = 50,
		Speed = NumberRange.new(5, 15),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 3),
			NumberSequenceKeypoint.new(1, 5)
		}),
	},
	
	-- Brake dust
	BrakeDust = {
		Enabled = true,
		Color = Color3.fromRGB(100, 100, 100),
		Lifetime = NumberRange.new(0.5, 1),
		Rate = 20,
	},
	
	-- Sparks from scraping
	Sparks = {
		Enabled = true,
		Color = Color3.fromRGB(255, 200, 100),
		Lifetime = NumberRange.new(0.2, 0.5),
		Rate = 30,
		Speed = NumberRange.new(20, 40),
	},
	
	-- Dust kicked up from tires
	DustClouds = {
		Enabled = true,
		Color = Color3.fromRGB(150, 140, 130),
		Lifetime = NumberRange.new(1, 2),
		Rate = 15,
	},
	
	-- Exhaust fumes
	Exhaust = {
		Enabled = true,
		Color = Color3.fromRGB(180, 180, 180),
		Lifetime = NumberRange.new(1, 2),
		Rate = 10,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 2)
		}),
		-- Heatwave distortion
		HeatDistortion = true,
	},
}

-- Light Effects
VisualEffects.Lighting = {
	-- Headlight
	Headlight = {
		Enabled = true,
		Brightness = 2,
		Range = 60, -- studs
		Angle = 90, -- degrees
		Color = Color3.fromRGB(255, 245, 230),
		
		-- Auto-toggle based on time
		AutoToggle = true,
		ToggleAtTime = 18, -- 6 PM
	},
	
	-- Taillight
	Taillight = {
		Enabled = true,
		Brightness = 1,
		Range = 15,
		Color = Color3.fromRGB(255, 0, 0),
		
		-- Brake light (brighter when braking)
		BrakeIntensity = 2.5,
	},
	
	-- Turn signals
	TurnSignals = {
		Enabled = true,
		Color = Color3.fromRGB(255, 165, 0),
		BlinkRate = 1, -- Hz
		Brightness = 1.5,
	},
	
	-- Underglow (optional cosmetic)
	Underglow = {
		Enabled = false,
		Color = Color3.fromRGB(0, 122, 255),
		Brightness = 1,
	},
}

-- Post-Processing Effects
VisualEffects.PostProcessing = {
	-- Bloom (glow effect)
	Bloom = {
		Enabled = true,
		Intensity = 0.3,
		Size = 24,
		Threshold = 0.8,
	},
	
	-- Color Correction
	ColorCorrection = {
		Enabled = true,
		Brightness = 0,
		Contrast = 0.1,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(255, 255, 255),
	},
	
	-- Sun Rays
	SunRays = {
		Enabled = true,
		Intensity = 0.15,
		Spread = 0.5,
	},
	
	-- Vignette (darkened edges)
	Vignette = {
		Enabled = false,
		Intensity = 0.5,
	},
	
	-- Depth of Field (blur background)
	DepthOfField = {
		Enabled = false, -- Performance intensive
		FocusDistance = 20,
		InFocusRadius = 15,
		NearIntensity = 0.5,
		FarIntensity = 0.5,
	},
}

-- Weather Effects
VisualEffects.Weather = {
	-- Rain effects
	Rain = {
		Enabled = true,
		
		-- Rain on screen
		ScreenDroplets = true,
		DropletsOnVisor = true, -- If using helmet cam
		
		-- Rain particles
		ParticleRate = 100,
		ParticleSpeed = NumberRange.new(50, 80),
		ParticleSize = NumberSequence.new(0.1, 0.3),
		
		-- Surface wetness
		WetRoads = true,
		WetnessReflection = 0.6,
		WetnessSpecular = 0.8,
		
		-- Reduced visibility
		FogIntensity = 0.4,
	},
	
	-- Wind effects
	Wind = {
		Enabled = true,
		
		-- Camera shake from wind
		WindShake = true,
		MaxWindShake = 0.2,
		
		-- Lean bike slightly in wind
		WindForce = true,
		MaxWindForce = 5, -- Force applied to bike
	},
}

-- Trail Effects
VisualEffects.Trails = {
	-- Tire trails
	TireMarks = {
		Enabled = true,
		
		-- Skid marks from braking/drifting
		SkidMarks = true,
		SkidMarkColor = Color3.fromRGB(30, 30, 30),
		SkidMarkLifetime = 30, -- seconds
		SkidMarkWidth = 0.3,
		
		-- Fade over time
		FadeTime = 10,
	},
	
	-- Light trails (optional cosmetic)
	LightTrails = {
		Enabled = false,
		Color = Color3.fromRGB(255, 100, 50),
		Lifetime = 0.5,
		Width = 0.5,
	},
}

-- UI Effects
VisualEffects.UI = {
	-- Speedometer effects
	Speedometer = {
		-- Needle animation
		NeedleSmoothing = true,
		SmoothingFactor = 0.15,
		
		-- Color changes at high RPM
		RedlineWarning = true,
		RedlineColor = Color3.fromRGB(255, 50, 50),
		RedlineFlash = true,
	},
	
	-- Damage indicators
	DamageVignette = {
		Enabled = false, -- No damage system yet
		Color = Color3.fromRGB(255, 0, 0),
		MaxIntensity = 0.5,
	},
	
	-- Speed warnings
	SpeedWarning = {
		Enabled = false,
		WarningSpeed = 250, -- km/h
		Color = Color3.fromRGB(255, 165, 0),
	},
}

-- Performance Settings
VisualEffects.Performance = {
	-- Quality presets
	Quality = "High", -- Low, Medium, High, Ultra
	
	-- LOD (Level of Detail)
	UseLOD = true,
	LODDistance = 100, -- studs
	
	-- Particle limits
	MaxParticles = 1000,
	MaxTrails = 50,
	
	-- Update rates
	EffectUpdateRate = 60, -- Hz
	ParticleUpdateRate = 30, -- Hz
}

return VisualEffects
