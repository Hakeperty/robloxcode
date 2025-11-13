-- HelmetCamera.client.lua
-- Locks the camera to a first-person helmet view with switchable visor tints when riding

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger
pcall(function()
	local Modules = ReplicatedStorage:WaitForChild("Modules", 2)
	if Modules then
		Logger = require(Modules:WaitForChild("ClientLogger", 2))
	end
end)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
if not camera then
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	camera = workspace.CurrentCamera
end

local function getCamera()
	camera = workspace.CurrentCamera or camera
	return camera
end

local HelmetCamera = {}
HelmetCamera.active = false
HelmetCamera.currentSeat = nil
HelmetCamera.currentHumanoid = nil
HelmetCamera.currentCharacter = nil
HelmetCamera.currentHead = nil
HelmetCamera.connections = {}
HelmetCamera.original = {}
HelmetCamera.currentTintIndex = 1
HelmetCamera.visorOptions = {
	{ name = "Clear", color = Color3.fromRGB(150, 158, 170), transparency = 0.92, vignette = 0.8, backdrop = 0.88 },
	{ name = "Light Smoke", color = Color3.fromRGB(105, 112, 125), transparency = 0.84, vignette = 0.72, backdrop = 0.84 },
	{ name = "Dark Smoke", color = Color3.fromRGB(60, 66, 78), transparency = 0.75, vignette = 0.62, backdrop = 0.81 },
	{ name = "Iridium", color = Color3.fromRGB(120, 90, 170), transparency = 0.78, vignette = 0.65, backdrop = 0.82 },
}
-- Camera positioning for optimal bike visibility
-- Head offset: slightly forward and down for natural rider perspective
HelmetCamera.headOffset = CFrame.new(0, 0.08, 0.35)
-- Helmet offset: positioned to see bike instruments and road ahead with downward angle
HelmetCamera.helmetOffset = CFrame.new(0, 1.35, 0.35) * CFrame.Angles(math.rad(-8), 0, 0)
HelmetCamera.hiddenParts = {}
HelmetCamera.hiddenDecals = {}
HelmetCamera.hiddenPartSignals = {}
HelmetCamera.hiddenDecalSignals = {}
HelmetCamera.loggingEnabled = false
HelmetCamera.lastLogTime = 0
HelmetCamera.logInterval = 1.5
HelmetCamera.lastCameraCFrame = nil
HelmetCamera.hintFadeThread = nil
HelmetCamera.headAdjustmentBuffer = {}
HelmetCamera.telemetryEvent = nil
HelmetCamera.settingsEvent = nil
HelmetCamera.lastClusterPayload = nil
HelmetCamera.clusterFrame = nil
HelmetCamera.clusterSpeedLabel = nil
HelmetCamera.clusterSpeedUnitLabel = nil
HelmetCamera.clusterRpmLabel = nil
HelmetCamera.clusterGearLabel = nil
HelmetCamera.clusterRpmBar = nil
HelmetCamera.clusterEnabled = true
HelmetCamera.maxClusterRpm = 13000
-- Slightly larger radius around head to force-hide nearby parts
HelmetCamera.hideRadius = 2.2 -- studs around head to force-hide any parts
-- Helmet visual effects
HelmetCamera.rainEnabled = false
HelmetCamera.rainIntensity = 0 -- 0..1
HelmetCamera.maxDroplets = 80
HelmetCamera.droplets = {}
HelmetCamera._dropPool = {}
HelmetCamera.rainLayer = nil
HelmetCamera.glareEnabled = true
HelmetCamera.autoTintEnabled = true
HelmetCamera.glareFrame = nil
HelmetCamera._lastRenderClock = nil
HelmetCamera.lastSpeedMps = 0
-- Turning dynamics
HelmetCamera._lookYawOffset = 0
HelmetCamera._rollOffset = 0
HelmetCamera.maxLookYawRad = math.rad(12) -- max look-ahead yaw from steering
HelmetCamera.maxCameraRollRad = math.rad(10) -- max camera roll to match lean
HelmetCamera.lookYawResponsiveness = 6.0 -- higher = snappier
HelmetCamera.rollResponsiveness = 4.0 -- higher = snappier
-- Visor runoff
HelmetCamera.runoff = 0 -- 0..1 accumulated bottom-edge water
HelmetCamera.runoffFrame = nil
-- Mouse look
HelmetCamera.enableMouseLook = false
HelmetCamera._yaw = 0
HelmetCamera._pitch = 0
HelmetCamera._sensitivity = 0.0025 -- radians per pixel
HelmetCamera._pitchLimit = math.rad(85)
HelmetCamera._mouseConn = nil
HelmetCamera._rmbConnBegin = nil
HelmetCamera._rmbConnEnd = nil
HelmetCamera._nextHeadSweep = 0
HelmetCamera.trackedHeadParts = {}
HelmetCamera._vehicleTrackConns = {}
HelmetCamera.predictedHeadCFrame = nil
-- Debug logging for body parts and ideal camera placement
HelmetCamera.debugBodyLogEnabled = false
-- Fogging and wipe
HelmetCamera.fogFrame = nil
HelmetCamera.fogAlpha = 0
HelmetCamera.fogTargetAlpha = 0
HelmetCamera.fogWipeTimeLeft = 0
HelmetCamera.wipeCooldownLeft = 0

function HelmetCamera:ensureOverlay()
	if self.overlayGui then
		return
	end

	local overlayGui = Instance.new("ScreenGui")
	overlayGui.Name = "HelmetOverlay"
	overlayGui.ResetOnSpawn = false
	overlayGui.IgnoreGuiInset = true
	overlayGui.Enabled = false
	overlayGui.DisplayOrder = 20
	overlayGui.Parent = player:WaitForChild("PlayerGui")

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Position = UDim2.fromScale(0.5, 0.5)
	backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5 -- reduced from 0.35 for better visibility
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 0
	backdrop.Parent = overlayGui

	-- Narrow the aperture to better cover edges, enhancing the helmet feel
	local visorWidth = 0.90
	local visorHeight = 0.74
	local visorCenterY = 0.52
	local topHeight = math.clamp(visorCenterY - (visorHeight / 2), 0, 1)
	local bottomHeight = math.clamp(1 - (visorCenterY + (visorHeight / 2)), 0, 1)
	local sideWidth = math.clamp((1 - visorWidth) / 2, 0, 1)

	local topMask = Instance.new("Frame")
	topMask.Name = "TopMask"
	topMask.Size = UDim2.new(1, 0, topHeight, 0)
	topMask.Position = UDim2.new(0, 0, 0, 0)
	topMask.BackgroundColor3 = Color3.new(0, 0, 0)
	topMask.BackgroundTransparency = 0
	topMask.BorderSizePixel = 0
	topMask.ZIndex = 3
	topMask.Parent = overlayGui

	local bottomMask = Instance.new("Frame")
	bottomMask.Name = "BottomMask"
	bottomMask.Size = UDim2.new(1, 0, bottomHeight, 0)
	bottomMask.Position = UDim2.new(0, 0, 1 - bottomHeight, 0)
	bottomMask.BackgroundColor3 = Color3.new(0, 0, 0)
	bottomMask.BackgroundTransparency = 0
	bottomMask.BorderSizePixel = 0
	bottomMask.ZIndex = 3
	bottomMask.Parent = overlayGui

	local leftMask = Instance.new("Frame")
	leftMask.Name = "LeftMask"
	leftMask.Size = UDim2.new(sideWidth, 0, 1, 0)
	leftMask.Position = UDim2.new(0, 0, 0, 0)
	leftMask.BackgroundColor3 = Color3.new(0, 0, 0)
	leftMask.BackgroundTransparency = 0
	leftMask.BorderSizePixel = 0
	leftMask.ZIndex = 3
	leftMask.Parent = overlayGui

	local rightMask = Instance.new("Frame")
	rightMask.Name = "RightMask"
	rightMask.Size = UDim2.new(sideWidth, 0, 1, 0)
	rightMask.Position = UDim2.new(1 - sideWidth, 0, 0, 0)
	rightMask.BackgroundColor3 = Color3.new(0, 0, 0)
	rightMask.BackgroundTransparency = 0
	rightMask.BorderSizePixel = 0
	rightMask.ZIndex = 3
	rightMask.Parent = overlayGui

	local visorFrame = Instance.new("Frame")
	visorFrame.Name = "VisorFrame"
	visorFrame.Size = UDim2.fromScale(0.92, 0.78)
	visorFrame.Position = UDim2.fromScale(0.5, 0.52)
	visorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	visorFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 45)
	visorFrame.BackgroundTransparency = 0.25
	visorFrame.BorderSizePixel = 0
	visorFrame.ZIndex = 1
	visorFrame.Parent = overlayGui

	local visorCorner = Instance.new("UICorner")
	visorCorner.CornerRadius = UDim.new(0, 160)
	visorCorner.Parent = visorFrame

	local visorStroke = Instance.new("UIStroke")
	visorStroke.Thickness = 8
	visorStroke.Color = Color3.fromRGB(30, 30, 35)
	visorStroke.Transparency = 0.1
	visorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	visorStroke.Parent = visorFrame

	local visorGradient = Instance.new("UIGradient")
	visorGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.4, 0.12),
		NumberSequenceKeypoint.new(0.75, 0.25),
		NumberSequenceKeypoint.new(1, 0.45)
	}
	visorGradient.Parent = visorFrame

	local vignette = Instance.new("Frame")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.fromScale(1.05, 1.05)
	vignette.Position = UDim2.fromScale(0.5, 0.52)
	vignette.AnchorPoint = Vector2.new(0.5, 0.5)
	vignette.BackgroundColor3 = Color3.new(0, 0, 0)
	vignette.BackgroundTransparency = 0.45
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 2
	vignette.Parent = overlayGui

	local vignetteGradient = Instance.new("UIGradient")
	vignetteGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	}
	vignetteGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.55, 0.35),
		NumberSequenceKeypoint.new(1, 0.95)
	}
	vignetteGradient.Parent = vignette

	local tintLabel = Instance.new("TextLabel")
	tintLabel.Name = "TintLabel"
	tintLabel.Size = UDim2.fromScale(0.3, 0.08)
	tintLabel.Position = UDim2.new(0.5, 0, 0.08, 0)
	tintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	tintLabel.BackgroundTransparency = 1
	tintLabel.Text = "Visor: Clear"
	tintLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
	tintLabel.TextSize = 18
	tintLabel.Font = Enum.Font.GothamBold
	tintLabel.ZIndex = 3
	tintLabel.Parent = overlayGui

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "HintLabel"
	hintLabel.Size = UDim2.fromScale(0.32, 0.06)
	hintLabel.Position = UDim2.new(0.5, 0, 0.94, 0)
	hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "Press [V] to change visor tint"
	hintLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
	hintLabel.TextSize = 16
	hintLabel.Font = Enum.Font.GothamSemibold
	hintLabel.ZIndex = 3
	hintLabel.Parent = overlayGui

	local clusterFrame = Instance.new("Frame")
	clusterFrame.Name = "ClusterFrame"
	clusterFrame.Size = UDim2.fromScale(0.34, 0.18)
	clusterFrame.Position = UDim2.fromScale(0.5, 0.99)
	clusterFrame.AnchorPoint = Vector2.new(0.5, 1)
	clusterFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	clusterFrame.BackgroundTransparency = 0.18
	clusterFrame.BorderSizePixel = 0
	clusterFrame.ZIndex = 4
	clusterFrame.Visible = false
	clusterFrame.Parent = overlayGui

	local clusterCorner = Instance.new("UICorner")
	clusterCorner.CornerRadius = UDim.new(0, 14)
	clusterCorner.Parent = clusterFrame

	local clusterStroke = Instance.new("UIStroke")
	clusterStroke.Thickness = 2
	clusterStroke.Color = Color3.fromRGB(60, 70, 90)
	clusterStroke.Transparency = 0.45
	clusterStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	clusterStroke.Parent = clusterFrame

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedValue"
	speedLabel.Size = UDim2.new(0.46, 0, 0.55, 0)
	speedLabel.Position = UDim2.new(0.05, 0, 0.18, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "000"
	speedLabel.TextColor3 = Color3.fromRGB(235, 245, 255)
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.TextScaled = true
	speedLabel.Font = Enum.Font.GothamBlack
	speedLabel.ZIndex = 5
	speedLabel.Parent = clusterFrame

	local speedUnit = Instance.new("TextLabel")
	speedUnit.Name = "SpeedUnit"
	speedUnit.Size = UDim2.new(0.2, 0, 0.28, 0)
	speedUnit.Position = UDim2.new(0.52, 0, 0.25, 0)
	speedUnit.BackgroundTransparency = 1
	speedUnit.Text = "km/h"
	speedUnit.TextColor3 = Color3.fromRGB(150, 165, 185)
	speedUnit.TextScaled = true
	speedUnit.Font = Enum.Font.GothamSemibold
	speedUnit.ZIndex = 5
	speedUnit.Parent = clusterFrame

	local gearLabel = Instance.new("TextLabel")
	gearLabel.Name = "GearValue"
	gearLabel.Size = UDim2.new(0.22, 0, 0.42, 0)
	gearLabel.Position = UDim2.new(0.78, 0, 0.1, 0)
	gearLabel.BackgroundTransparency = 1
	gearLabel.Text = "N"
	gearLabel.TextColor3 = Color3.fromRGB(255, 235, 120)
	gearLabel.TextScaled = true
	gearLabel.Font = Enum.Font.GothamBold
	gearLabel.ZIndex = 5
	gearLabel.Parent = clusterFrame

	local rpmLabel = Instance.new("TextLabel")
	rpmLabel.Name = "RpmValue"
	rpmLabel.Size = UDim2.new(0.42, 0, 0.32, 0)
	rpmLabel.Position = UDim2.new(0.54, 0, 0.6, 0)
	rpmLabel.BackgroundTransparency = 1
	rpmLabel.Text = "0.0k"
	rpmLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
	rpmLabel.TextScaled = true
	rpmLabel.Font = Enum.Font.GothamMedium
	rpmLabel.ZIndex = 5
	rpmLabel.Parent = clusterFrame

	local rpmBarBackground = Instance.new("Frame")
	rpmBarBackground.Name = "RpmBar"
	rpmBarBackground.Size = UDim2.new(0.9, 0, 0.18, 0)
	rpmBarBackground.Position = UDim2.new(0.05, 0, 0.78, 0)
	rpmBarBackground.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
	rpmBarBackground.BackgroundTransparency = 0.25
	rpmBarBackground.BorderSizePixel = 0
	rpmBarBackground.ZIndex = 4
	rpmBarBackground.Parent = clusterFrame

	local rpmBarCorner = Instance.new("UICorner")
	rpmBarCorner.CornerRadius = UDim.new(0, 8)
	rpmBarCorner.Parent = rpmBarBackground

	local rpmBarFill = Instance.new("Frame")
	rpmBarFill.Name = "Fill"
	rpmBarFill.Size = UDim2.new(0.1, 0, 1, 0)
	rpmBarFill.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	rpmBarFill.BorderSizePixel = 0
	rpmBarFill.ZIndex = 5
	rpmBarFill.Parent = rpmBarBackground

	local rpmFillCorner = Instance.new("UICorner")
	rpmFillCorner.CornerRadius = UDim.new(0, 8)
	rpmFillCorner.Parent = rpmBarFill

	local rpmFillGradient = Instance.new("UIGradient")
	rpmFillGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(130, 225, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 90))
	}
	rpmFillGradient.Parent = rpmBarFill

	self.overlayGui = overlayGui
	self.backdropFrame = backdrop
	self.visorFrame = visorFrame
	self.vignetteFrame = vignette
	self.tintLabel = tintLabel
	self.hintLabel = hintLabel
	self.clusterFrame = clusterFrame
	self.clusterSpeedLabel = speedLabel
	self.clusterSpeedUnitLabel = speedUnit
	self.clusterGearLabel = gearLabel
	self.clusterRpmLabel = rpmLabel
	self.clusterRpmBar = rpmBarFill
	self:updateCluster(0, 0, "N")

	-- Rain droplet layer (topmost visuals under text)
	local rainLayer = Instance.new("Frame")
	rainLayer.Name = "RainLayer"
	rainLayer.Size = UDim2.fromScale(1, 1)
	rainLayer.Position = UDim2.fromScale(0.5, 0.5)
	rainLayer.AnchorPoint = Vector2.new(0.5, 0.5)
	rainLayer.BackgroundTransparency = 1
	rainLayer.ZIndex = 6
	rainLayer.Parent = overlayGui
	self.rainLayer = rainLayer

	-- Sun glare strip near the top of visor
	local glare = Instance.new("Frame")
	glare.Name = "Glare"
	glare.Size = UDim2.fromScale(1.05, 0.16)
	glare.Position = UDim2.fromScale(0.5, 0.03)
	glare.AnchorPoint = Vector2.new(0.5, 0)
	glare.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glare.BackgroundTransparency = 1
	glare.BorderSizePixel = 0
	glare.ZIndex = 5
	glare.Parent = overlayGui
	local glareGrad = Instance.new("UIGradient")
	glareGrad.Rotation = 0
	glareGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.0, 1.0),
		NumberSequenceKeypoint.new(0.6, 0.35),
		NumberSequenceKeypoint.new(1.0, 1.0)
	}
	glareGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
	}
	glareGrad.Parent = glare
	self.glareFrame = glare

	-- Storm flash layer (top-most white flash)
	local flash = Instance.new("Frame")
	flash.Name = "StormFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.Position = UDim2.fromScale(0.5, 0.5)
	flash.AnchorPoint = Vector2.new(0.5, 0.5)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 8
	flash.Parent = overlayGui
	self.flashFrame = flash

	-- Fog layer (below droplets, above visor)
	local fog = Instance.new("Frame")
	fog.Name = "Fog"
	fog.Size = UDim2.fromScale(1, 1)
	fog.Position = UDim2.fromScale(0.5, 0.5)
	fog.AnchorPoint = Vector2.new(0.5, 0.5)
	fog.BackgroundColor3 = Color3.fromRGB(220, 230, 240)
	fog.BackgroundTransparency = 1
	fog.BorderSizePixel = 0
	fog.ZIndex = 5
	fog.Parent = overlayGui
	local fogGrad = Instance.new("UIGradient")
	fogGrad.Rotation = 0
	fogGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.00, 0.0),  -- top opaque-ish
		NumberSequenceKeypoint.new(0.25, 0.15),
		NumberSequenceKeypoint.new(0.50, 0.35),
		NumberSequenceKeypoint.new(0.75, 0.15),
		NumberSequenceKeypoint.new(1.00, 0.0)   -- bottom opaque-ish
	}
	fogGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220,230,240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220,230,240))
	}
	fogGrad.Parent = fog
	self.fogFrame = fog

	-- Bottom-edge runoff visual (thin glossy strip that grows with accumulated droplets)
	local runoff = Instance.new("Frame")
	runoff.Name = "Runoff"
	runoff.Size = UDim2.new(0.2, 0, 0, 2)
	runoff.Position = UDim2.fromScale(0.5, 0.995)
	runoff.AnchorPoint = Vector2.new(0.5, 1)
	runoff.BackgroundColor3 = Color3.fromRGB(220, 230, 245)
	runoff.BackgroundTransparency = 1
	runoff.BorderSizePixel = 0
	runoff.ZIndex = 7
	runoff.Parent = overlayGui
	local runoffGrad = Instance.new("UIGradient")
	runoffGrad.Rotation = 0
	runoffGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 0.95)
	}
	runoffGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220,230,245)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220,230,245))
	}
	runoffGrad.Parent = runoff
	self.runoffFrame = runoff
end

function HelmetCamera:refreshHintLabel(text, duration)
	if not self.hintLabel then
		return
	end

	if self.hintFadeThread then
		task.cancel(self.hintFadeThread)
		self.hintFadeThread = nil
	end

	if text then
		self.hintLabel.Text = text
	end

	self.hintLabel.TextTransparency = 0
	self.hintLabel.Visible = true

	if TweenService then
		TweenService:Create(
			self.hintLabel,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 0 }
		):Play()
	end

	if duration and duration > 0 then
		self.hintFadeThread = task.delay(duration, function()
			if not self.hintLabel then
				return
			end
			if TweenService then
				TweenService:Create(
					self.hintLabel,
					TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ TextTransparency = 1 }
				):Play()
			else
				self.hintLabel.TextTransparency = 1
			end
		end)
	end
end

function HelmetCamera:clearHiddenAssets()
	self.hiddenParts = {}
	self.hiddenDecals = {}
	self:disconnectVisibilityGuards()
end

-- Spawn a single procedural droplet as a rounded frame with gradient
function HelmetCamera:_getPooled(kind)
	local pool = self._dropPool[kind]
	if pool and #pool > 0 then
		local ui = table.remove(pool)
		ui.Visible = true
		ui.BackgroundTransparency = 0.2
		ui.Rotation = 0
		return ui
	end
	return nil
end

function HelmetCamera:_returnToPool(kind, ui)
	if not ui then return end
	ui.Visible = false
	ui.Parent = self.rainLayer
	self._dropPool[kind] = self._dropPool[kind] or {}
	table.insert(self._dropPool[kind], ui)
end

function HelmetCamera:_spawnDroplet()
	if not self.rainLayer or #self.droplets >= self.maxDroplets then
		return
	end
	local drop = self:_getPooled("drop") or Instance.new("Frame")
	drop.Name = "Drop"
	local w = math.random(4, 10)
	local h = math.random(10, 22)
	drop.Size = UDim2.fromOffset(w, h)
	-- Bias spawn near the top edge for realism
	local x = math.random()
	local y = -0.12 + math.random() * 0.05
	drop.Position = UDim2.new(x, 0, y, 0)
	drop.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
	drop.BackgroundTransparency = 0.2
	drop.BorderSizePixel = 0
	drop.ZIndex = 6
	if not drop:FindFirstChildOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, math.floor(w/2))
		corner.Parent = drop
		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180,195,220))
		}
		grad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0.1)
		}
		grad.Parent = drop
		drop.Parent = self.rainLayer
	end
	table.insert(self.droplets, {
		ui = drop,
		vy = math.random(28, 60),
		sway = (math.random() * 2 - 1) * 0.2,
		life = 0,
		kind = "drop"
	})
end

function HelmetCamera:_spawnDropletAt(xScale)
	if not self.rainLayer or #self.droplets >= self.maxDroplets then
		return
	end
	local drop = self:_getPooled("drop") or Instance.new("Frame")
	drop.Name = "Drop"
	local w = math.random(4, 10)
	local h = math.random(10, 22)
	drop.Size = UDim2.fromOffset(w, h)
	drop.Position = UDim2.new(math.clamp(xScale,0,1), 0, -0.05, 0)
	drop.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
	drop.BackgroundTransparency = 0.2
	drop.BorderSizePixel = 0
	drop.ZIndex = 6
	if not drop:FindFirstChildOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, math.floor(w/2))
		corner.Parent = drop
		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180,195,220))
		}
		grad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0.1)
		}
		grad.Parent = drop
		drop.Parent = self.rainLayer
	end
	table.insert(self.droplets, {
		ui = drop,
		vy = math.random(28, 60),
		sway = (math.random() * 2 - 1) * 0.2,
		life = 0,
		kind = "drop"
	})
end

function HelmetCamera:_spawnSplatAt(xScale)
	if not self.rainLayer then return end
	local splat = self:_getPooled("splat") or Instance.new("Frame")
	splat.Name = "Splat"
	local s = math.random(14, 26)
	splat.Size = UDim2.fromOffset(s, s)
	splat.Position = UDim2.new(math.clamp(xScale,0,1), 0, -0.02, 0)
	splat.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
	splat.BackgroundTransparency = 0.35
	splat.BorderSizePixel = 0
	splat.ZIndex = 6
	if not splat:FindFirstChildOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = splat
		local grad = Instance.new("UIGradient")
		grad.Rotation = 0
		grad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.0),
			NumberSequenceKeypoint.new(1, 0.9)
		}
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200,210,225))
		}
		grad.Parent = splat
		splat.Parent = self.rainLayer
	end
	table.insert(self.droplets, {
		ui = splat,
		vy = math.random(10, 18),
		sway = (math.random() * 2 - 1) * 0.1,
		life = 0,
		kind = "splat"
	})
end

function HelmetCamera:_updateRain(dt, speedMps, cameraCFrame)
	if not self.rainLayer then return end

	-- Read optional external attributes for weather control
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local attr = ReplicatedStorage:GetAttribute("RainIntensity")
	if typeof(attr) == "number" then
		self.rainIntensity = math.clamp(attr, 0, 1)
		self.rainEnabled = self.rainIntensity > 0.02
	end

	-- Spawn rate scales with intensity and speed
	if self.rainEnabled then
		local targetCount = math.floor(self.maxDroplets * self.rainIntensity)
		while #self.droplets < targetCount do
			-- Small chance to spawn a splat instead of a standard drop
			if math.random() < 0.08 * self.rainIntensity then
				self:_spawnSplatAt(math.random())
			else
				self:_spawnDroplet()
			end
		end
	end

	-- Update droplets with speed-based streaking and light merging
	local toRemove = nil
	for i = #self.droplets, 1, -1 do
		local d = self.droplets[i]
		local ui = d.ui
		if not ui or not ui.Parent then
			table.remove(self.droplets, i)
		else
			d.life = d.life + dt
			local pos = ui.Position
			-- Wind and directionality: project airflow onto screen space for lateral drift/rotation
			local windDir = Vector3.new(0,0,0)
			local windSpeed = 0
			local gust = 0
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local wd = ReplicatedStorage:GetAttribute("WindDirection")
			if typeof(wd) == "Vector3" then
				windDir = wd.Magnitude > 0 and wd.Unit or windDir
			end
			local ws = ReplicatedStorage:GetAttribute("WindSpeed")
			if typeof(ws) == "number" then
				windSpeed = math.max(0, ws)
			end
			local wg = ReplicatedStorage:GetAttribute("WindGust")
			if typeof(wg) == "number" then
				gust = math.clamp(wg, 0, 1)
			end

			local airflowRight = 0
			if cameraCFrame then
				local right = cameraCFrame.RightVector
				local forward = cameraCFrame.LookVector
				-- Relative airflow approximated by speed forward minus wind
				local rel = forward * speedMps - windDir * windSpeed
				airflowRight = rel:Dot(right) -- lateral component
			end

			local vx = d.sway * (1 + speedMps * 0.02) + airflowRight * 0.02
			local vy = (d.vy + speedMps * 3.0 + windSpeed * (0.5 + 0.8 * gust)) * dt
			ui.Position = UDim2.new(pos.X.Scale + vx * dt, 0, pos.Y.Scale + vy * 0.01, 0)
			-- Visual tilt with lateral airflow
			ui.Rotation = math.clamp(airflowRight * 0.9, -22, 22)

			-- Convert drops to streaks at higher speeds
			if d.kind == "drop" and speedMps > 22 then
				local size = ui.Size
				local newH = math.min(60, size.Y.Offset + speedMps * 0.4)
				local newW = math.max(2, size.X.Offset - 0.25)
				ui.Size = UDim2.fromOffset(newW, newH)
				ui.BackgroundTransparency = math.clamp(ui.BackgroundTransparency + dt * 0.25, 0.15, 0.6)
				d.kind = "streak"
			end

			local removed = false
			if d.kind == "splat" and d.life > 0.12 then
				-- Break into a few smaller droplets
				local x = ui.Position.X.Scale
				self:_spawnDropletAt(x - math.random()*0.03)
				self:_spawnDropletAt(x + math.random()*0.03)
				if math.random() < 0.5 then
					self:_spawnDropletAt(x)
				end
				self:_returnToPool("splat", ui)
				table.remove(self.droplets, i)
				removed = true
			end

			if not removed and ui.Position.Y.Scale > 1.05 then
				self:_returnToPool(d.kind, ui)
				table.remove(self.droplets, i)
			end
		end
	end

	if not self.rainEnabled then
		-- Fade out remaining droplets slowly when rain stops
		for i = #self.droplets, 1, -1 do
			local d = self.droplets[i]
			local ui = d.ui
			if ui then
				ui.BackgroundTransparency = math.min(1, ui.BackgroundTransparency + dt * 0.5)
				if ui.BackgroundTransparency >= 0.99 then
					self:_returnToPool(d.kind, ui)
					table.remove(self.droplets, i)
				end
			else
				table.remove(self.droplets, i)
			end
		end
	end
end

function HelmetCamera:_updateFog(dt, speedMps)
	if not self.fogFrame then return end
	-- Target fog alpha grows with rain and decreases with speed
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ri = ReplicatedStorage:GetAttribute("RainIntensity")
	local rain = 0
	if typeof(ri) == "number" then
		rain = math.clamp(ri, 0, 1)
	end
	local wet = 0
	local wi = ReplicatedStorage:GetAttribute("Wetness")
	if typeof(wi) == "number" then
		wet = math.clamp(wi, 0, 1)
	end

	-- Improved speed-based fog clearing curve
	local speedFactor = math.max(0, 1 - (speedMps / 20)) -- clear faster at high speed
	speedFactor = speedFactor ^ 1.5 -- exponential curve for more dramatic clearing
	
	local baseTarget = rain * speedFactor * 0.35 -- cap ~0.35 (reduced from 0.6)
	baseTarget = baseTarget + wet * speedFactor * 0.12 -- reduced wetness contribution
	self.fogTargetAlpha = baseTarget
	if self.fogWipeTimeLeft > 0 then
		self.fogTargetAlpha = 0
		self.fogWipeTimeLeft = math.max(0, self.fogWipeTimeLeft - dt)
	end

	-- Smooth towards target
	local diff = self.fogTargetAlpha - self.fogAlpha
	self.fogAlpha = self.fogAlpha + diff * math.min(1, dt * 3.0)
	self.fogFrame.BackgroundTransparency = 1 - self.fogAlpha
end

function HelmetCamera:wipeVisor()
	if self.wipeCooldownLeft and self.wipeCooldownLeft > 0 then
		return
	end
	self.fogWipeTimeLeft = 2.0
	self.wipeCooldownLeft = 1.0
	-- Clear top third droplets quickly
	for i = #self.droplets, 1, -1 do
		local d = self.droplets[i]
		local ui = d.ui
		if ui and ui.Parent and ui.Position.Y.Scale < 0.35 then
			self:_returnToPool(d.kind, ui)
			table.remove(self.droplets, i)
		end
	end
	self:refreshHintLabel("Visor wiped", 1.0)
end

function HelmetCamera:_updateGlare(cameraCFrame)
	if not self.glareEnabled or not self.glareFrame then return end
	local Lighting = game:GetService("Lighting")
	local sunDir = Lighting:GetSunDirection()
	-- If sun is below horizon, reduce glare
	local sunUpness = math.max(0, sunDir.Y)
	local camLook = cameraCFrame.LookVector
	-- Glare stronger when sun is in front
	local facing = math.max(0, sunDir:Dot(camLook))
	local intensity = math.clamp(facing * 0.9 + sunUpness * 0.3, 0, 1)

	-- Optional external override
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local attr = ReplicatedStorage:GetAttribute("SunGlareIntensity")
	if typeof(attr) == "number" then
		intensity = math.clamp(attr, 0, 1)
	end

	self.glareFrame.BackgroundTransparency = 1 - (intensity * 0.35)

	-- Auto-tint: brighten (clearer) when glare strong, darken otherwise
	if self.autoTintEnabled and self.visorOptions and #self.visorOptions > 0 then
		local newIndex
		if intensity > 0.75 then
			newIndex = 1 -- Clear
		elseif intensity > 0.45 then
			newIndex = 2 -- Light Smoke
		else
			newIndex = 3 -- Darker
		end
		if newIndex ~= self.currentTintIndex then
			self.currentTintIndex = newIndex
			self:applyTint()
		end
	end
end

function HelmetCamera:recordHeadAdjustment(part, reason)
	if not part then
		return
	end

	self.headAdjustmentBuffer = self.headAdjustmentBuffer or {}
	table.insert(self.headAdjustmentBuffer, {
		name = part:GetFullName(),
		reason = reason or "hidden",
	})
end

function HelmetCamera:flushHeadAdjustmentLog(context)
	local buffer = self.headAdjustmentBuffer
	if not buffer or #buffer == 0 then
		return
	end

	print(string.format("[HelmetCamera] Hidden %d head assets (%s)", #buffer, context or "update"))
	for index, entry in ipairs(buffer) do
		local label = entry.reason and tostring(entry.reason) or "hidden"
		print(string.format("   #%d %s - %s", index, entry.name, label))
	end
	self.headAdjustmentBuffer = {}
end

function HelmetCamera:hidePartLocally(part, reason)
	if not part or not part:IsA("BasePart") then
		return
	end

	if not self.hiddenParts[part] then
		self.hiddenParts[part] = {
			localTransparency = part.LocalTransparencyModifier,
			castShadow = part.CastShadow,
		}
	end

	part.LocalTransparencyModifier = 1
	part.CastShadow = false
	self:recordHeadAdjustment(part, reason)
	self:watchHiddenPart(part)

	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("Decal") then
			if not self.hiddenDecals[descendant] then
				self.hiddenDecals[descendant] = descendant.Transparency
			end
			descendant.Transparency = 1
			self:watchHiddenDecal(descendant)
		end
	end
end

function HelmetCamera:restoreHiddenAssets()
	self:disconnectVisibilityGuards()

	for part, original in pairs(self.hiddenParts) do
		if part and part.Parent then
			if type(original) == "table" then
				part.LocalTransparencyModifier = original.localTransparency or 0
				if original.castShadow ~= nil then
					part.CastShadow = original.castShadow
				else
					part.CastShadow = true
				end
			else
				part.LocalTransparencyModifier = original or 0
				part.CastShadow = true
			end
		end
	end

	for decal, original in pairs(self.hiddenDecals) do
		if decal and decal.Parent then
			decal.Transparency = original or 0
		end
	end

	self:clearHiddenAssets()
end

function HelmetCamera:disconnectVisibilityGuards()
	for part, connection in pairs(self.hiddenPartSignals) do
		if connection then
			connection:Disconnect()
		end
		self.hiddenPartSignals[part] = nil
	end

	for decal, connection in pairs(self.hiddenDecalSignals) do
		if connection then
			connection:Disconnect()
		end
		self.hiddenDecalSignals[decal] = nil
	end
end

function HelmetCamera:watchHiddenPart(part)
	if not part then
		return
	end

	if self.hiddenPartSignals[part] then
		return
	end

	local signal = part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
		if not self.active then
			return
		end

		if self.hiddenParts[part] and part.LocalTransparencyModifier < 0.99 then
			part.LocalTransparencyModifier = 1
		end
	end)

	self.hiddenPartSignals[part] = signal
end

function HelmetCamera:watchHiddenDecal(decal)
	if not decal then
		return
	end

	if self.hiddenDecalSignals[decal] then
		return
	end

	local signal = decal:GetPropertyChangedSignal("Transparency"):Connect(function()
		if not self.active then
			return
		end

		if self.hiddenDecals[decal] ~= nil and decal.Transparency < 0.99 then
			decal.Transparency = 1
		end
	end)

	self.hiddenDecalSignals[decal] = signal
end

function HelmetCamera:hideCharacterHead(character)
	if not character then
		return
	end

	-- Ensure any previous state is cleared before reapplying
	self:restoreHiddenAssets()
	self.headAdjustmentBuffer = {}

	local head = character:FindFirstChild("Head")
	if head then
		self.currentHead = head
		self:hidePartLocally(head, "Character head mesh")
	end

	for _, descendant in ipairs(character:GetChildren()) do
		if descendant:IsA("Accessory") then
			local handle = descendant:FindFirstChild("Handle")
			if handle then
				self:hidePartLocally(handle, string.format("Accessory:%s", descendant.Name))
			end
		elseif descendant:IsA("BasePart") then
			local lowerName = string.lower(descendant.Name)
			if lowerName:find("head") or lowerName:find("hair") or lowerName:find("helmet") then
				self:hidePartLocally(descendant, string.format("Extra part:%s", descendant.Name))
			end
		end
	end

	-- Distance-based hide near head (extra-sure suppression)
	if head then
		local radius = self.hideRadius or 1.5
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part ~= head then
				-- Exclude HumanoidRootPart to avoid odd side-effects
				if part.Name ~= "HumanoidRootPart" then
					local ok, pos = pcall(function() return part.Position end)
					if ok then
						local dist = (pos - head.Position).Magnitude
						if dist <= radius then
							self:hidePartLocally(part, string.format("Near head (%.2f studs):%s", dist, part.Name))
						end
					end
				end
			end
		end
	end

	self:flushHeadAdjustmentLog("Initial hide")
end

-- Hide rider head proxies and any nearby parts on the current vehicle (e.g., car.Misc.Anims.* NewHead)
function HelmetCamera:hideVehicleNearCamera(cameraCFrame)
	local seat = self.currentSeat
	if not seat or not seat.Parent or not cameraCFrame then return end
	local root = seat.Parent
	local camPos = cameraCFrame.Position
	local radius = (self.hideRadius or 1.5) + 0.5
	local camTightRadius = 0.85 -- force-hide head-like parts extremely close to camera
	local function isRiderProxy(inst)
		-- Identify rider mesh proxies under bike (e.g., car.Misc.Anims.*)
		local p = inst
		local seenAnims = false
		while p and p ~= root do
			if p.Name == "Anims" or (p.Parent and p.Parent.Name == "Anims") then
				seenAnims = true
				break
			end
			p = p.Parent
		end
		return seenAnims
	end
	for _, part in ipairs(root:GetDescendants()) do
		if part:IsA("BasePart") then
			local nameLower = string.lower(part.Name)
			local ok, pos = pcall(function() return part.Position end)
			if ok then
				local dist = (pos - camPos).Magnitude
				local nameMatch = nameLower:find("head") or nameLower == "newhead" or nameLower:find("helmet") or nameLower:find("hair")
				if (isRiderProxy(part) and (dist <= radius or dist <= camTightRadius)) or nameMatch then
					self:hidePartLocally(part, string.format("Vehicle near-cam (%.2f):%s", dist, part.Name))
				end
			end
		elseif part:IsA("Decal") and (part.Name == "face" or string.lower(part.Name):find("face")) then
			part.Transparency = 1
		end
	end
end

-- Build and maintain a tracked set of rider head proxy parts under the current vehicle
function HelmetCamera:_isHeadLikeName(name)
	local lower = string.lower(tostring(name))
	return lower == "newhead" or lower:find("head") ~= nil or lower:find("helmet") ~= nil or lower:find("hair") ~= nil
end

function HelmetCamera:_indexVehicleHeadParts(root)
	if not root then return end
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("BasePart") then
			local p = inst.Parent
			local underAnims = false
			while p and p ~= root do
				if p.Name == "Anims" then underAnims = true break end
				p = p.Parent
			end
			if underAnims and self:_isHeadLikeName(inst.Name) then
				self.trackedHeadParts[inst] = true
			end
		end
	end
end

function HelmetCamera:_connectVehicleHeadTracking(root)
	self:_disconnectVehicleHeadTracking()
	self.trackedHeadParts = {}
	if not root then return end
	self:_indexVehicleHeadParts(root)
	if Logger then
		local count = 0
		for _ in pairs(self.trackedHeadParts) do count = count + 1 end
		Logger.Info("Camera", "TrackVehicleHeads", { count = count, root = root:GetFullName() })
	end

	local addedConn = root.DescendantAdded:Connect(function(inst)
		if not self.active then return end
		if inst:IsA("BasePart") and self:_isHeadLikeName(inst.Name) then
			-- Only track under Anims tree
			local p = inst.Parent
			local underAnims = false
			while p and p ~= root do
				if p.Name == "Anims" then underAnims = true break end
				p = p.Parent
			end
			if underAnims then
				self.trackedHeadParts[inst] = true
				if Logger then Logger.Info("Camera", "TrackHeadAdded", { part = inst:GetFullName() }) end
			end
		end
	end)
	table.insert(self._vehicleTrackConns, addedConn)

	local removingConn = root.DescendantRemoving:Connect(function(inst)
		if self.trackedHeadParts[inst] then
			self.trackedHeadParts[inst] = nil
			if Logger then Logger.Info("Camera", "TrackHeadRemoved", { part = inst:GetFullName() }) end
		end
	end)
	table.insert(self._vehicleTrackConns, removingConn)
end

function HelmetCamera:_disconnectVehicleHeadTracking()
	for _, conn in ipairs(self._vehicleTrackConns) do
		if conn then conn:Disconnect() end
	end
	self._vehicleTrackConns = {}
	self.trackedHeadParts = {}
end

-- Predict character head transform via Neck Motor6D even if head reference is temporarily missing
function HelmetCamera:_computePredictedHead(character)
	if not character then return nil end
	local upper = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not upper or not upper:IsA("BasePart") then return nil end
	local neck = upper:FindFirstChild("Neck") or character:FindFirstChild("Neck")
	if not neck or not neck:IsA("Motor6D") then return nil end
	local part0 = neck.Part0
	local part1 = neck.Part1
	if not part0 or not part1 then return nil end
	-- Motor rule: part0.CFrame * C0 == part1.CFrame * C1
	-- => head CFrame ~= upper.CFrame * C0 * C1:Inverse()
	local ok, cf = pcall(function()
		return part0.CFrame * neck.C0 * neck.C1:Inverse()
	end)
	if ok then return cf end
	return nil
end

function HelmetCamera:observeCharacterAccessories(character)
	if self.connections.accessoryAdded then
		self.connections.accessoryAdded:Disconnect()
		self.connections.accessoryAdded = nil
	end

	if not character then
		return
	end

	local function handleChild(child)
		if not self.active then
			return
		end

		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle then
				self:hidePartLocally(handle, string.format("Accessory:%s", child.Name))
			end
		elseif child:IsA("BasePart") then
			local lowerName = string.lower(child.Name)
			if lowerName:find("head") or lowerName:find("hair") or lowerName:find("helmet") then
				self:hidePartLocally(child, string.format("Extra part:%s", child.Name))
			end
		end

		self:flushHeadAdjustmentLog(string.format("Accessory update: %s", child.Name))
	end

	self.connections.accessoryAdded = character.ChildAdded:Connect(function(child)
		task.defer(handleChild, child)
	end)

	for _, child in ipairs(character:GetChildren()) do
		task.defer(handleChild, child)
	end
end

function HelmetCamera:updateTintLabel()
	if not self.tintLabel then
		return
	end

	local option = self.visorOptions[self.currentTintIndex]
	if option then
		self.tintLabel.Text = string.format("Visor: %s", option.name)
	else
		self.tintLabel.Text = "Visor"
	end
end

function HelmetCamera:updateCluster(speed, rpm, gear)
	if not self.clusterFrame then
		return
	end

	self.lastClusterPayload = self.lastClusterPayload or { speed = 0, rpm = 0, gear = "N" }
	local payload = self.lastClusterPayload
	if speed ~= nil then
		payload.speed = speed
	end
	if rpm ~= nil then
		payload.rpm = rpm
	end
	if gear ~= nil and gear ~= "" then
		payload.gear = tostring(gear)
	end

	local currentSpeed = payload.speed or 0
	local currentRpm = payload.rpm or 0
	local currentGear = payload.gear or "N"

	if self.clusterSpeedLabel then
		local roundedSpeed = math.clamp(math.floor(currentSpeed + 0.5), 0, 399)
		self.clusterSpeedLabel.Text = string.format("%03d", roundedSpeed)
	end

	if self.clusterSpeedUnitLabel then
		self.clusterSpeedUnitLabel.Text = "km/h"
	end

	if self.clusterGearLabel then
		self.clusterGearLabel.Text = string.upper(currentGear)
	end

	local rpmLabel = self.clusterRpmLabel
	local rpmValue = math.max(currentRpm or 0, 0)
	if rpmLabel then
		rpmLabel.Text = string.format("%.1fk", rpmValue / 1000)
	end

	local rpmBar = self.clusterRpmBar
	if rpmBar then
		local normalized = 0
		if self.maxClusterRpm > 0 then
			normalized = math.clamp(rpmValue / self.maxClusterRpm, 0, 1)
		end
		rpmBar.Size = UDim2.new(math.max(0.05, normalized), 0, 1, 0)

		local rpmColor
		if normalized >= 0.98 then
			rpmColor = Color3.fromRGB(255, 70, 70)
		elseif normalized >= 0.85 then
			rpmColor = Color3.fromRGB(255, 150, 70)
		elseif normalized >= 0.6 then
			rpmColor = Color3.fromRGB(255, 215, 90)
		else
			rpmColor = Color3.fromRGB(120, 200, 255)
		end
		rpmBar.BackgroundColor3 = rpmColor
		if rpmLabel then
			rpmLabel.TextColor3 = rpmColor
		end
	end

	if self.clusterFrame then
		self.clusterFrame.Visible = self.active and self.clusterEnabled
	end
end

function HelmetCamera:ensureTelemetryEvent()
	if self.telemetryEvent and self.telemetryEvent.Parent then
		return self.telemetryEvent
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	local event = playerGui:FindFirstChild("HelmetTelemetry")
	if not event then
		event = Instance.new("BindableEvent")
		event.Name = "HelmetTelemetry"
		event.Parent = playerGui
	end

	self.telemetryEvent = event
	return event
end

function HelmetCamera:ensureSettingsEvent()
	if self.settingsEvent and self.settingsEvent.Parent then
		return self.settingsEvent
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	local event = playerGui:FindFirstChild("HelmetSettings")
	if not event then
		event = Instance.new("BindableEvent")
		event.Name = "HelmetSettings"
		event.Parent = playerGui
	end

	self.settingsEvent = event
	return event
end

function HelmetCamera:connectSettings()
	if self.connections.settings then
		return
	end

	local event = self:ensureSettingsEvent()
	if not event then
		return
	end

	self.connections.settings = event.Event:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		local cmd = tostring(payload.command or "")
		if cmd == "SetClusterEnabled" then
			local enabled = not not payload.enabled
			self.clusterEnabled = enabled
			self:updateCluster(nil, nil, nil)
		end
	end)
end

function HelmetCamera:disconnectSettings()
	if self.connections.settings then
		self.connections.settings:Disconnect()
		self.connections.settings = nil
	end
end

function HelmetCamera:connectTelemetry()
	if self.connections.telemetry then
		return
	end

	local event = self:ensureTelemetryEvent()
	if not event then
		return
	end

	self.connections.telemetry = event.Event:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		self:updateCluster(payload.speed, payload.rpm, payload.gear)
	end)
end

function HelmetCamera:disconnectTelemetry()
	if self.connections.telemetry then
		self.connections.telemetry:Disconnect()
		self.connections.telemetry = nil
	end
end

function HelmetCamera:applyTint()
	self:ensureOverlay()
	local option = self.visorOptions[self.currentTintIndex]
	local frame = self.visorFrame
	if not option or not frame then
		return
	end

	frame.BackgroundColor3 = option.color
	frame.BackgroundTransparency = option.transparency
	if self.backdropFrame then
		self.backdropFrame.BackgroundTransparency = option.backdrop or 0.86 -- improved default from 0.8
	end
	if self.vignetteFrame then
		self.vignetteFrame.BackgroundTransparency = option.vignette or 0.6
	end
	self:updateTintLabel()
end

function HelmetCamera:cycleTint()
	self.currentTintIndex = self.currentTintIndex + 1
	if self.currentTintIndex > #self.visorOptions then
		self.currentTintIndex = 1
	end
	self:applyTint()
end

function HelmetCamera:setLoggingEnabled(enabled)
	if self.loggingEnabled == enabled then
		return
	end

	self.loggingEnabled = enabled
	self.lastLogTime = 0
	if enabled then
		print("[HelmetCamera] Logging ENABLED")
	else
		print("[HelmetCamera] Logging disabled")
	end
end

local function formatVector(vec)
	if not vec then
		return "n/a"
	end
	return string.format("%.2f, %.2f, %.2f", vec.X, vec.Y, vec.Z)
end

-- Build a compact snapshot of key body part positions
local function _vec3(v)
	return { x = v.X, y = v.Y, z = v.Z }
end

function HelmetCamera:_collectBodySnapshot()
	local char = self.currentCharacter
	if not char then return nil end
	local function posOf(name)
		local p = char:FindFirstChild(name)
		if p and p:IsA("BasePart") then return _vec3(p.Position) end
		return nil
	end
	local snap = {
		HumanoidRootPart = posOf("HumanoidRootPart"),
		Head = posOf("Head"),
		UpperTorso = posOf("UpperTorso") or posOf("Torso"),
		LowerTorso = posOf("LowerTorso"),
		LeftUpperArm = posOf("LeftUpperArm"),
		LeftLowerArm = posOf("LeftLowerArm"),
		LeftHand = posOf("LeftHand"),
		RightUpperArm = posOf("RightUpperArm"),
		RightLowerArm = posOf("RightLowerArm"),
		RightHand = posOf("RightHand"),
		LeftUpperLeg = posOf("LeftUpperLeg"),
		LeftLowerLeg = posOf("LeftLowerLeg"),
		LeftFoot = posOf("LeftFoot"),
		RightUpperLeg = posOf("RightUpperLeg"),
		RightLowerLeg = posOf("RightLowerLeg"),
		RightFoot = posOf("RightFoot"),
	}
	return snap
end

function HelmetCamera:logState(finalCFrame, source, idealCFrame)
	if not finalCFrame then
		return
	end

	local now = os.clock()
	if now - (self.lastLogTime or 0) < self.logInterval then
		return
	end

	self.lastLogTime = now
	local head = self.currentHead
	local seat = self.currentSeat
	local humanoid = self.currentHumanoid
	local rootPart = humanoid and humanoid.RootPart or nil

	if Logger then
		Logger.Info("Camera", "Frame", {
			source = source or "render",
			cam = _vec3(finalCFrame.Position),
			ideal = idealCFrame and _vec3(idealCFrame.Position) or nil,
			head = head and { x = head.Position.X, y = head.Position.Y, z = head.Position.Z } or nil,
			seat = seat and { x = seat.Position.X, y = seat.Position.Y, z = seat.Position.Z } or nil,
			root = rootPart and { x = rootPart.Position.X, y = rootPart.Position.Y, z = rootPart.Position.Z } or nil,
			speedMps = self.lastSpeedMps or 0,
			rain = game:GetService("ReplicatedStorage"):GetAttribute("RainIntensity") or 0,
			drops = #self.droplets,
			body = self.debugBodyLogEnabled and self:_collectBodySnapshot() or nil,
		})
	end
end

function HelmetCamera:connectInputHandlers()
	if self.connections.input then
		return
	end

	self.connections.input = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not self.active then
			return
		end

		if input.KeyCode == Enum.KeyCode.V then
			self:cycleTint()
			if Logger then Logger.Info("Input", "VisorTintCycle") end
		elseif input.KeyCode == Enum.KeyCode.L then
			self:setLoggingEnabled(not self.loggingEnabled)
			if Logger then Logger.Info("Input", "ToggleInternalLog", { enabled = self.loggingEnabled }) end
		elseif input.KeyCode == Enum.KeyCode.X then
			self:wipeVisor()
			if Logger then Logger.Info("Input", "WipeVisor") end
		elseif input.KeyCode == Enum.KeyCode.F8 then
			self.debugBodyLogEnabled = not self.debugBodyLogEnabled
			self.lastLogTime = 0 -- force next frame to log immediately
			if Logger then Logger.Info("Camera", "DebugBodyToggle", { enabled = self.debugBodyLogEnabled }) end
		end
	end)

	if not self._mouseConn then
		self._mouseConn = UserInputService.InputChanged:Connect(function(input)
			if not self.active or not self.enableMouseLook then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local dx, dy = input.Delta.X, input.Delta.Y
				self._yaw = self._yaw + (-dx * self._sensitivity)
				self._pitch = self._pitch + (-dy * self._sensitivity)
				if self._pitch > self._pitchLimit then self._pitch = self._pitchLimit end
				if self._pitch < -self._pitchLimit then self._pitch = -self._pitchLimit end
			end
		end)
	end

	-- Right Mouse Button: hold to mouse-look (locks cursor while held only)
	if not self._rmbConnBegin then
		self._rmbConnBegin = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or not self.active then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				self.enableMouseLook = true
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false
				if Logger then Logger.Info("Input", "RMBHold", { active = true }) end
			end
		end)
	end
	if not self._rmbConnEnd then
		self._rmbConnEnd = UserInputService.InputEnded:Connect(function(input)
			if not self.active then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				self.enableMouseLook = false
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
				if Logger then Logger.Info("Input", "RMBHold", { active = false }) end
			end
		end)
	end
end

function HelmetCamera:disconnectInputHandlers()
	if self.connections.input then
		self.connections.input:Disconnect()
		self.connections.input = nil
	end
	if self._mouseConn then
		self._mouseConn:Disconnect()
		self._mouseConn = nil
	end
	if self._rmbConnBegin then
		self._rmbConnBegin:Disconnect()
		self._rmbConnBegin = nil
	end
	if self._rmbConnEnd then
		self._rmbConnEnd:Disconnect()
		self._rmbConnEnd = nil
	end
end

function HelmetCamera:startCameraLoop()
	if self.connections.renderLoop then
		return
	end

	self.connections.renderLoop = RunService.RenderStepped:Connect(function()
		if not self.active then
			return
		end

		local targetCFrame
		local humanoid = self.currentHumanoid
		local head = self.currentHead
		local character = self.currentCharacter

		if (not head or not head.Parent) and character then
			head = character:FindFirstChild("Head")
			self.currentHead = head
		end
		if humanoid and humanoid.RootPart then
			if head and head.Parent then
				targetCFrame = head.CFrame * self.headOffset
			else
				-- Prefer a bike-provided camera mount if available
				local seat = self.currentSeat
				local camPart = nil
				if seat and seat.Parent then
					local body = seat.Parent:FindFirstChild("Body")
					if body then
						camPart = body:FindFirstChild("Cam") or body:FindFirstChild("RCam")
					end
				end
				if camPart and camPart:IsA("BasePart") then
					targetCFrame = camPart.CFrame
				else
					targetCFrame = humanoid.RootPart.CFrame * self.helmetOffset
				end
			end
		elseif head and head.Parent then
			targetCFrame = head.CFrame * self.headOffset
		elseif self.currentSeat then
			local seat = self.currentSeat
			local camPart = nil
			if seat and seat.Parent then
				local body = seat.Parent:FindFirstChild("Body")
				if body then
					camPart = body:FindFirstChild("Cam") or body:FindFirstChild("RCam")
				end
			end
			if camPart and camPart:IsA("BasePart") then
				targetCFrame = camPart.CFrame
			else
				targetCFrame = self.currentSeat.CFrame * self.helmetOffset
			end
		end

		if not targetCFrame then
			self:exit()
			return
		end

		local referencePart = (humanoid and humanoid.RootPart) or self.currentSeat or head
		local referenceCFrame = referencePart and referencePart.CFrame or targetCFrame
		local blendedLook = (referenceCFrame.LookVector * 0.25 + targetCFrame.LookVector * 0.75)
		if blendedLook.Magnitude < 1e-4 then
			blendedLook = referenceCFrame.LookVector
		else
			blendedLook = blendedLook.Unit
		end

		local blendedUp = (referenceCFrame.UpVector * 0.35 + targetCFrame.UpVector * 0.65)
		if blendedUp.Magnitude < 1e-4 or math.abs(blendedUp:Dot(blendedLook)) > 0.98 then
			blendedUp = Vector3.new(0, 1, 0)
		else
			blendedUp = blendedUp.Unit
		end

		local finalCFrame = CFrame.lookAt(targetCFrame.Position, targetCFrame.Position + blendedLook, blendedUp)
		-- Apply mouse look offsets (first-person head aim)
		if self.enableMouseLook then
			finalCFrame = finalCFrame * CFrame.Angles(0, self._yaw, 0) * CFrame.Angles(self._pitch, 0, 0)
		end



		-- Update helmet visuals and head occlusion guards
		local now = os.clock()
		local dt = 1/60
		if self._lastRenderClock then
			dt = math.max(1/240, math.min(1/15, now - self._lastRenderClock))
		end
		self._lastRenderClock = now

		local speedMps = 0
		if humanoid and humanoid.RootPart then
			speedMps = humanoid.RootPart.AssemblyLinearVelocity.Magnitude
		end
		self.lastSpeedMps = speedMps

		-- Look-ahead yaw from steering and subtle camera roll to match lean
		local steer = 0
		if self.currentSeat and self.currentSeat:IsA("VehicleSeat") then
			local okVal, val = pcall(function() return self.currentSeat.SteerFloat end)
			if not okVal then
				okVal, val = pcall(function() return self.currentSeat.Steer end)
			end
			if okVal and typeof(val) == "number" then
				steer = math.clamp(val, -1, 1)
			end
		end
		local speedNorm = math.clamp((self.lastSpeedMps or 0) / 40, 0, 1)
		local yawTarget = steer * self.maxLookYawRad * speedNorm
		self._lookYawOffset = self._lookYawOffset + (yawTarget - self._lookYawOffset) * math.min(1, dt * self.lookYawResponsiveness)

		-- Estimate lean from reference orientation (right vector Y indicates tilt)
		local ref = referenceCFrame
		local lean = 0
		if ref then
			local rv = ref.RightVector
			lean = -math.asin(math.clamp(rv.Y, -1, 1)) -- negative to tilt into turn
		end
		local rollTarget = math.clamp(lean * 0.4, -self.maxCameraRollRad, self.maxCameraRollRad)
		self._rollOffset = self._rollOffset + (rollTarget - self._rollOffset) * math.min(1, dt * self.rollResponsiveness)

		-- Apply yaw look-ahead then roll around camera forward axis
		finalCFrame = finalCFrame * CFrame.Angles(0, self._lookYawOffset, 0)
		finalCFrame = finalCFrame * CFrame.Angles(0, 0, self._rollOffset)
		if self.lastCameraCFrame then
			finalCFrame = self.lastCameraCFrame:Lerp(finalCFrame, 0.65)
		end
		self.lastCameraCFrame = finalCFrame

		local activeCamera = getCamera()
		if activeCamera then
			activeCamera.CFrame = finalCFrame
		end
		self:_updateRain(dt, speedMps, finalCFrame)
		self:_updateGlare(finalCFrame)
		self:_updateFog(dt, speedMps)
		if self.wipeCooldownLeft and self.wipeCooldownLeft > 0 then
			self.wipeCooldownLeft = math.max(0, self.wipeCooldownLeft - dt)
		end

		-- Update predicted head pose using Neck joint (used for occlusion if head ref is momentarily missing)
		self.predictedHeadCFrame = self:_computePredictedHead(self.currentCharacter)

		-- Occasional lightning flash
		local flashAttr = game:GetService("ReplicatedStorage"):GetAttribute("StormFlash")
		if self.flashFrame and typeof(flashAttr) == "number" and flashAttr > 0 then
			if not self._stormFlashCooldown or self._stormFlashCooldown <= 0 then
				self._stormFlashCooldown = 0.8
				self.flashFrame.BackgroundTransparency = 0.2
				if TweenService then
					TweenService:Create(self.flashFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
				else
					self.flashFrame.BackgroundTransparency = 1
				end
			end
		else
			if self._stormFlashCooldown and self._stormFlashCooldown > 0 then
				self._stormFlashCooldown = math.max(0, self._stormFlashCooldown - dt)
			end
		end

		-- Subtle speed-based FOV for sense of speed
		if activeCamera then
			local baseFov = 75
			local extra = math.clamp((speedMps - 5) * 0.25, 0, 12)
			activeCamera.FieldOfView = baseFov + extra
		end

		-- Always ensure tracked vehicle head proxies remain hidden
		for part, _ in pairs(self.trackedHeadParts) do
			if part and part.Parent then
				self:hidePartLocally(part, "Tracked vehicle head")
			end
		end

		-- Periodic sweep to re-hide any new head/near-head parts that animations add
		if now >= (self._nextHeadSweep or 0) then
			self._nextHeadSweep = now + 0.25
			local char = self.currentCharacter
			local head = self.currentHead or (char and char:FindFirstChild("Head"))
			local headPosForSweep = nil
			if head and head.Parent then
				headPosForSweep = head.Position
			elseif self.predictedHeadCFrame then
				headPosForSweep = self.predictedHeadCFrame.Position
			end
			if char and headPosForSweep then
				local radius = self.hideRadius or 1.5
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part ~= head and part.Name ~= "HumanoidRootPart" then
						local ok, pos = pcall(function() return part.Position end)
						if ok then
							local dist = (pos - headPosForSweep).Magnitude
							if dist <= radius then
								self:hidePartLocally(part, string.format("Near head (%.2f studs):%s", dist, part.Name))
							end
						end
					end
				end
			end
			-- Also sweep the current vehicle around the camera position
			self:hideVehicleNearCamera(finalCFrame)
		end

		self:logState(finalCFrame, "render", targetCFrame)
	end)
end

function HelmetCamera:stopCameraLoop()
	if self.connections.renderLoop then
		self.connections.renderLoop:Disconnect()
		self.connections.renderLoop = nil
	end
end

function HelmetCamera:enter(seat, humanoid)
	if self.active and seat == self.currentSeat then
		return
	end

	self:ensureOverlay()
	self.active = true
	self.currentSeat = seat
	self.currentHumanoid = humanoid
	self.currentCharacter = humanoid and humanoid.Parent or self.currentCharacter

	-- Begin tracking rider head proxies on this vehicle
	if self.currentSeat and self.currentSeat.Parent then
		self:_connectVehicleHeadTracking(self.currentSeat.Parent)
	end

	if self.currentCharacter then
		self:hideCharacterHead(self.currentCharacter)
	end
	self:observeCharacterAccessories(self.currentCharacter)

	local activeCamera = getCamera()
	self.original.cameraType = activeCamera and activeCamera.CameraType or Enum.CameraType.Custom
	self.original.fieldOfView = activeCamera and activeCamera.FieldOfView or 70
	self.original.cameraMode = player.CameraMode
	self.original.minZoom = player.CameraMinZoomDistance
	self.original.maxZoom = player.CameraMaxZoomDistance
	local okDev, devLock = pcall(function() return player.DevEnableMouseLock end)
	if okDev then
		self.original.devEnableMouseLock = devLock
	else
		self.original.devEnableMouseLock = nil
	end

	if activeCamera then
		activeCamera.CameraType = Enum.CameraType.Scriptable
		activeCamera.FieldOfView = 75
	end
	-- Keep mouse free by default; hold RMB for mouse-look
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	player.CameraMode = Enum.CameraMode.Classic
	pcall(function()
		player.DevEnableMouseLock = false
	end)
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5

	self.overlayGui.Enabled = true
	self:applyTint()
	self:refreshHintLabel("Press [V] visor tint  |  [X] wipe  |  Hold RMB: look", 6)
	self:connectTelemetry()
	self:connectSettings()
	if self.clusterFrame then
		self.clusterFrame.Visible = self.clusterEnabled
		if self.lastClusterPayload then
			self:updateCluster(self.lastClusterPayload.speed, self.lastClusterPayload.rpm, self.lastClusterPayload.gear)
		else
			self:updateCluster(0, 0, "N")
		end
	end
	self:connectInputHandlers()
	self:startCameraLoop()
	-- Initial sweep for vehicle rider proxies near camera
	local activeCam = getCamera()
	if activeCam then
		self:hideVehicleNearCamera(activeCam.CFrame)
	end
end

function HelmetCamera:exit()
	if not self.active then
		return
	end

	self.active = false
	self.currentSeat = nil
	self.currentHumanoid = nil
	self.currentHead = nil
	self.lastCameraCFrame = nil

	self:stopCameraLoop()
	self:disconnectInputHandlers()
	self:disconnectTelemetry()
	self:disconnectSettings()
	self:restoreHiddenAssets()

	-- Stop tracking any vehicle rider proxies
	self:_disconnectVehicleHeadTracking()

	if self.connections.accessoryAdded then
		self.connections.accessoryAdded:Disconnect()
		self.connections.accessoryAdded = nil
	end

	local activeCamera = getCamera()
	if activeCamera then
		activeCamera.CameraType = self.original.cameraType or Enum.CameraType.Custom
		activeCamera.FieldOfView = self.original.fieldOfView or 70
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	player.CameraMode = self.original.cameraMode or Enum.CameraMode.Classic
	player.CameraMinZoomDistance = self.original.minZoom or 0.5
	player.CameraMaxZoomDistance = self.original.maxZoom or 12
    if self.original.devEnableMouseLock ~= nil then
        player.DevEnableMouseLock = self.original.devEnableMouseLock
    end

	if self.overlayGui then
		self.overlayGui.Enabled = false
	end
	if self.clusterFrame then
		self.clusterFrame.Visible = false
	end
end

function HelmetCamera:onSeatChanged(humanoid)
	local seat = humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		self:enter(seat, humanoid)
	else
		self:exit()
	end
end

function HelmetCamera:trackHumanoid(humanoid)
	if self.connections.seatChanged then
		self.connections.seatChanged:Disconnect()
	end

	if self.connections.died then
		self.connections.died:Disconnect()
	end

	self.connections.seatChanged = humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		self:onSeatChanged(humanoid)
	end)

	self.connections.died = humanoid.Died:Connect(function()
		self:exit()
	end)

	self:onSeatChanged(humanoid)
end

function HelmetCamera:setupCharacter(character)
	self:exit()
	self.currentCharacter = character

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10)
	end

	if humanoid then
		self:trackHumanoid(humanoid)
	end
end

-- Re-apply head hiding after appearance loads/changes
player.CharacterAppearanceLoaded:Connect(function(char)
	if HelmetCamera.currentCharacter == char and HelmetCamera.active then
		HelmetCamera:hideCharacterHead(char)
	end
end)

player.CharacterAdded:Connect(function(char)
	HelmetCamera:setupCharacter(char)
end)

if player.Character then
	HelmetCamera:setupCharacter(player.Character)
end

return HelmetCamera
