local Tune = {}

--[[Misc]]--
Tune.LoadDelay = 1 --Delay before initializing chassis (in seconds, increase for more reliable initialization)
Tune.AutoStart = true --Set to false if using manual ignition plugin

--[[Weight and CG]]--
Tune.Weight = 439 + 150 --Bike weight in LBS (199kg wet weight + 150lb rider)

Tune.WeightBrickSize	= {	--Size of weight brick (dimmensions in studs ; larger = more stable)
	--[[Width]]	3	,
	--[[Height]]	3	,
	--[[Length]]	8	}

Tune.WeightDistribution = 45 --Slightly more weight on the rear for easier wheelies
Tune.CGHeight = 0.7 --Lowered CG for better stability, but still allows wheelies
Tune.WBVisible = false --Makes the weight brick visible (Debug)
Tune.BalVisible = false --Makes the balance brick visible (Debug)

--[[Unsprung Weight]]--
Tune.FWheelDensity = .1 -- Front Wheel Density
Tune.RWheelDensity = .1 -- Rear Wheel Density

Tune.AxleSize = 1 -- Size of structural members (larger = more stable/carry more weight)
Tune.AxleDensity = .1 -- Density of structural members
Tune.AxlesVisible = false -- Makes axle structural parts visible (Debug)

Tune.HingeSize = 1 -- Size of steering hinges (larger = more stable/carry more weight)
Tune.HingeDensity = .1 -- Density of steering hinges
Tune.HingesVisible = false -- Makes steering hinge structural parts visible (Debug)

--[[Tires]]--

--[[Front]]--
Tune.FTireProfile = 1 --You can tune the profile of your tire here, making it more aggressive or smooth, with the help of a graph: https://www.desmos.com/calculator/og4x1gyzng
Tune.FProfileHeight = .4 --You can tune the height of the profile, making it conform to your tire, with the help of a graph: https://www.desmos.com/calculator/og4x1gyzng

Tune.FTireWear = 0.7 --Dictates how fast tires wear, put to 0 to disable tire wear (UI will disappear)
Tune.FTireCompound = 1 --The more compounds you have, the harder your tire will get towards the middle, sacrificing grip for wear
Tune.FTireFriction = 1.1 --Your tire's friction in the best conditions.
Tune.FTireSpinRatio = .5 --How much friction your tires are going to lose under spinning
Tune.FTireLockRatio = .5 --How much friction your tires are going to lose under locking up

--[[Rear]]--
Tune.RTireProfile = 1 --You can tune the profile of your tire here, making it more aggressive or smooth, with the help of a graph: https://www.desmos.com/calculator/og4x1gyzng
Tune.RProfileHeight = .45 --You can tune the height of the profile, making it conform to your tire, with the help of a graph: https://www.desmos.com/calculator/og4x1gyzng

Tune.RTireWear = 0.7 --Dictates how fast tires wear, put to 0 to disable tire wear (UI will disappear)
Tune.RTireCompound = 1 --The more compounds you have, the harder your tire will get towards the middle, sacrificing grip for wear
Tune.RTireFriction = 1.1 --Your tire's friction in the best conditions.
Tune.RTireSpinRatio = .5 --How much friction your tires are going to lose under spinning
Tune.RTireLockRatio = .5 --How much friction your tires are going to lose under locking up

Tune.TireCylinders = 8 --How many cylinders are used for the tires. More means a smoother curve but way more parts meaning lag. (Default = 4)
Tune.TiresVisible = false --Makes the tires visible (Debug)

--[[Suspensions]]--
Tune.Suspensions = true --Enables or disables suspensions

--[[Front]]--
Tune.FSuspensionDamping = 120 --Dampening
Tune.FSuspensionStiffness = 4500 --Stiffness
Tune.FSuspensionLength = 2.35 --Suspension length (in studs)
Tune.FPreCompression = .25 -- Vehicle height, relative to your suspension settings
Tune.FExtensionLimit = .8 --Max Extension Travel (in studs)
Tune.FCompressLimit = .4 --Max Compression Travel (in studs)
Tune.FBaseOffset	= {			-- Suspension (steering point) base
	--[[Lateral]]		0		,	-- positive = outward
	--[[Vertical]]		0	,	-- positive = upward
	--[[Forward]]		.106		}	-- positive = forward
Tune.FAxleOffset	= {			-- Suspension (axle point) base
	--[[Lateral]]		0		,	-- positive = outward
	--[[Vertical]]		0		,	-- positive = upward
	--[[Forward]]		0		}	-- positive = forward
Tune.FBricksVisible = false --Makes the front suspension bricks visible (Debug)
Tune.FConstsVisible = false --Makes the front suspension constraints visible (Debug)

--[[Rear]]--
Tune.RSuspensionDamping = 120 --Dampening
Tune.RSuspensionStiffness = 4000 --Stiffness
Tune.RSuspensionLength = 1.85 --Suspension length (in studs)
Tune.RPreCompression = -0.1 -- Vehicle height, relative to your suspension settings
Tune.RExtensionLimit = .2 --Max Extension Travel (in studs)
Tune.RCompressLimit = .8 --Max Compression Travel (in studs)
Tune.RBaseOffset	= {			-- Suspension base point
	--[[Lateral]]		0		,	-- positive = outward
	--[[Vertical]]		1.7		,	-- positive = upward
	--[[Forward]]		-.5		}	-- positive = forward
Tune.RBricksVisible = false --Makes the front suspension bricks visible (Debug)
Tune.RConstsVisible = false --Makes the front suspension constraints visible (Debug)

--[[Wheel Stabilizer Gyro]]--
Tune.FGyroDamp = 0 --Front Wheel Non-Axial Dampening
Tune.RGyroDamp = 0 --Rear Wheel Non-Axial Dampening


--[[Steering]]--

--[[Handlebars]]--
Tune.SteerAngle = 20	--Handlebar angle at max lock (in degrees)
Tune.MSteerExp = 1 --Mouse steering exponential degree
Tune.LowSpeedCut = 30 --Low speed steering cutoff, tune according to your full lock, a bike with a great handlebar lock angle will need a lower value (E.G. If your full lock is 20 your cutoff will be 40/50, or if your full lock is 40 your cutoff will be 20/30)

Tune.SteerD = 50 --Dampening of the Low speed steering
Tune.SteerMaxTorque = 4000 --Force of the the Low speed steering
Tune.SteerP = 500 --Aggressiveness of the the Low speed steering

Tune.SDamper = false --Handlebar dampening, usually equipped on supersport motorcycles to avoid tankslapping, it slows down the handlebars movement
Tune.SteerDamperD = 0 --Dampening of the Damper
Tune.SteerDamperMaxTorque = 0 --Force of the the Damper
Tune.SteerDamperP = 0 --Aggressiveness of the the Damper

--[[Leaning]]--
Tune.LeanSpeed = .35 --How quickly the the bike will lean, .01 being slow, 1 being almost instantly
Tune.LeanProgressiveness = 30 --How much steering is kept at higher speeds, a lower number is less steering, a higher number is more steering
Tune.MaxLean = 58 --Maximum lean angle in degrees

Tune.LeanD = 150 --Dampening of the lean
Tune.LeanMaxTorque = 9000 --Force of the lean
Tune.LeanP = 2500 --Aggressiveness of the lean



--[[Aerodynamics]]--
Tune.DragCoefficient = .65 --Coefficient of drag, the higher it is the more your bike will have resistance to air



--[[Brakes]]--
Tune.FBrakeForce = 300 --Front brake force
Tune.RBrakeForce = 200 --Rear brake force

Tune.PBrakeForce = 500 --Rear brake force



--[[Engine]]--
Tune.Engine = true --Can be disabled for motorless vehicles
Tune.AutoStart = true --Can be disabled if ignition is handled by something else
Tune.EngineType = "Petrol" --[[ OPTIONS
    "Petrol"	;	Traditional petrol/gasoline engine
    "Electric"	;	Electric engine/motor ]]

--[[Engine Tune]]--

--Torque Curve

Tune.Horsepower		= 200		--	[TORQUE CURVE VISUAL] -- Increased for more power
Tune.IdleRPM		= 1000		--	https://www.desmos.com/calculator/nap6stpjqf
Tune.PeakRPM		= 12500		--	Use sliders to manipulate values -- Adjusted for a more realistic power band
Tune.Redline		= 13800		--	Copy and paste slider values into the respective tune values
Tune.EqPoint		= 7252
Tune.PeakSharpness	= 2
Tune.CurveMult		= 0.02

Tune.FlyWheel = 50 --Flywheel weight, a lighter flywheel makes the engine more responsive

--Aspiration
Tune.Aspiration = "Natural"	--[[ OPTIONS
    "Natural"	;	N/A, Naturally aspirated engine
    "Single"	;	Single turbocharger
    "Double"	;	Twin turbocharger ]]

Tune.Boost = 15			--Max PSI per turbo (If you have two turbos and this is 15, the PSI will be 30)
Tune.TurboSize = 80		--Turbo size; the bigger it is, the more lag it has.
Tune.CompressRatio = 9	--The compression ratio (look it up)

--[[Transmission]]--
Tune.TransmissionType = "DCT" --[[ OPTIONS
    "Manual"	;	Traditional clutch operated manual transmission
    "CVT"		;	One gear transmission, with a contiuously varying ratio (Used in scooters)
    "DCT"		;	Dual clutch transmission, where clutch is operated automatically ]]
Tune.ShiftTime = .1 -- The time delay in which you initiate a shift and the bike changes gear

--[[Gear Ratios]]--
Tune.FinalDrive		= (38/16)*1.6	--(Final * Primary)	-- Gearing determines top speed and wheel torque
--for the final is recommended to divide the size of the rear sprocket to the one of the front sprocket
--and multiply it to the primary drive ratio, if data is missing, you can also just use a single number
Tune.Ratios			= {				-- Higher ratio = more torque, Lower ratio = higher top speed
	--[[Neutral]]	0			,	-- Ratios can also be deleted
	--[[ 1 ]]		32/14		,	-- Reverse, Neutral, and 1st gear are required
	--[[ 2 ]]		32/18		,
	--[[ 3 ]]		33/22		,
	--[[ 4 ]]		32/24		,
	--[[ 5 ]]		34/28		,
	--[[ 6 ]]		33/29		,
}

--[[Temporary Values]]--
Tune.RevAccel = 350 -- Increased for faster revving
Tune.RevDecay = 100
Tune.RevBounce = 800
Tune.ClutchTol = 250

--[[Clutch]]--
Tune.ClutchBite = 10 --Clutch aggressiveness
Tune.SlipperClutch = false --Slips the clutch under heavy engine braking, making the bike less likely to unsettle during hard braking



--[[QuickShifter]]--
Tune.QuickShifterBlipper = false --[MANUAL ONLY] The quickshifter cuts off the ignition, allowing for lighting fast clutchless upshifts and downshifts.



--[[Speed Limiter]]--
Tune.Limiter = false --Enables a speed limiter
Tune.SpeedLimit = 300 --At what speed (SPS) the limiter engages



--[[Driving Aids]]--
Tune.BurnoutEnabled = true -- Allows for burnouts (holding brake + throttle)

Tune.ABS = false --Avoids brakes locking up, reducing risk of lowside
Tune.ABSThreshold = 30 --Slip speed allowed before ABS starts working (in SPS)
Tune.AntiStoppie = false --Avoids front flipping during heavy braking

Tune.TCS = true --Enabled to prevent wheelspin
Tune.TCSThreshold = 15 --Engages sooner to control spin
Tune.TCSGradient = 10 --How quickly TCS ramps up
Tune.TCSLimit = 20 --Allows for a small amount of slip

Tune.LinkedBrakes = true --Links brakes up, uses both brakes while braking
Tune.BrakesRatio = 60 --When the linked brakes are on, this dictates which brakes are gonna be used more (0 = rear brake; 100 = front brake)

Tune.AntiWheelie = false --Avoids wheelies by cutting off the throttle
Tune.CruiseControl = false --Mantains a set speed
Tune.LaunchControl = false --Once activated, accellerate to keep your RPMs to the ideal conditions.

Tune.AutoShift = true --The bike will automatically shift for you
Tune.AutoShiftMode = "RPM" --[[ OPTIONS
    "RPM"	;	Shifts based on RPM
    "Speed"	;	Shifts based on wheel speed ]]

Tune.AutoUpThreshold	= 200 --Automatic upshift point (relative to peak RPM, positive = Over-rev)
Tune.AutoDownThreshold = 1400 --Automatic downshift point (relative to peak RPM, positive = Under-rev)



--[[Controls]]--

Tune.Peripherals = {
	MSteerWidth				= 67		,	-- Mouse steering control width	(0 - 100% of screen width)
	MSteerDZone				= 10		,	-- Mouse steering deadzone (0 - 100%)

	ControlLDZone			= 15			,	-- Controller steering L-deadzone (0 - 100%)
	ControlRDZone			= 15			,	-- Controller steering R-deadzone (0 - 100%)
}

Tune.Controls = {

	--Keyboard Controls
	--Mode Toggles
	ToggleTCS				= Enum.KeyCode.T					,
	ToggleABS				= Enum.KeyCode.Y					,
	ToggleAuto				= Enum.KeyCode.M					,
	ToggleMouseDrive		= Enum.KeyCode.R					,

	--Primary Controls
	Throttle				= Enum.KeyCode.Up					,
	Brake					= Enum.KeyCode.Down					,
	SteerLeft				= Enum.KeyCode.Left					,
	SteerRight				= Enum.KeyCode.Right				,

	--Secondary Controls
	Throttle2				= Enum.KeyCode.W					,
	Brake2					= Enum.KeyCode.S					,
	SteerLeft2				= Enum.KeyCode.A					,
	SteerRight2				= Enum.KeyCode.D					,

	--Manual Transmission
	ShiftUp					= Enum.KeyCode.E					,
	ShiftDown				= Enum.KeyCode.Q					,
	Clutch					= Enum.KeyCode.P					,

	--Handbrake
	PBrake					= Enum.KeyCode.LeftShift			,

	--Mouse Controls
	MouseThrottle			= Enum.UserInputType.MouseButton1	,
	MouseBrake				= Enum.UserInputType.MouseButton2	,
	MouseClutch				= Enum.KeyCode.W					,
	MouseShiftUp			= Enum.KeyCode.E					,
	MouseShiftDown			= Enum.KeyCode.Q					,
	MousePBrake				= Enum.KeyCode.LeftShift			,

	--Controller Mapping
	ContlrThrottle			= Enum.KeyCode.ButtonR2				,
	ContlrBrake				= Enum.KeyCode.ButtonL2				,
	ContlrSteer				= Enum.KeyCode.Thumbstick1			,
	ContlrShiftUp			= Enum.KeyCode.ButtonY				,
	ContlrShiftDown			= Enum.KeyCode.ButtonX				,
	ContlrClutch			= Enum.KeyCode.ButtonR1				,
	ContlrPBrake			= Enum.KeyCode.ButtonL1				,
	ContlrToggleAuto		= Enum.KeyCode.DPadUp				,
	ContlrToggleTCS			= Enum.KeyCode.DPadDown				,
	ContlrToggleABS			= Enum.KeyCode.DPadRight			,
}

--[[	STANDARDIZED STUFF: DON'T TOUCH UNLESS NEEDED	]]--

--[[Weight Scaling]]--
--[[Cubic stud : pounds ratio]]--
Tune.WeightScaling = 1/130 --Default = 1/50 (1 cubic stud = 50 lbs)

--[[Timing and Data Caching]]--
Tune.EngineRefRt = 15 --Refresh rate for power output (ticks/second | Higher = smoother output / more runtime cpu load)
Tune.CacheTorque = true --Enables pre-calculated torque caching (less runtime cpu load, more memory usage)
Tune.CacheRPMInc = 100 --RPM increment size for plotting torque (lower = closer to actual curve / more memory usage)

return Tune
