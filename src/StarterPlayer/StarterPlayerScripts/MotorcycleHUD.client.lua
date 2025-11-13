-- MotorcycleHUD.lua
-- Motorcycle dashboard with speedometer, RPM, gear, and traction control

print("🏍️ Loading Motorcycle HUD system...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientLogger"))
	end)
	if ok then Logger = mod end
end

local PRIMARY_REDUCTION_RATIO = 1.717 -- 79/46 primary gears
local FINAL_DRIVE_RATIO = 42 / 16 -- stock sprockets on the 2008 Fireblade
local WHEEL_CIRCUMFERENCE_METERS = 1.99 -- 190/50ZR17 tyre (approx.)
local ENGINE_IDLE_RPM = 1300
local ENGINE_REDLINE_RPM = 13000

local GEAR_RATIOS = {
	[1] = 2.286,
	[2] = 1.778,
	[3] = 1.500,
	[4] = 1.333,
	[5] = 1.214,
	[6] = 1.130,
}

local ORDERED_GEARS = { 1, 2, 3, 4, 5, 6 }

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("✓ Motorcycle HUD services loaded")

local MotorcycleHUD = {}
MotorcycleHUD.TractionControl = true
MotorcycleHUD.CurrentBike = nil
MotorcycleHUD.CurrentSeat = nil
MotorcycleHUD.InterfaceGui = nil
MotorcycleHUD.ValuesFolder = nil
MotorcycleHUD.RPMValue = nil
MotorcycleHUD.GearValue = nil
MotorcycleHUD.SpeedValue = nil
MotorcycleHUD.AutoShiftValue = nil
MotorcycleHUD.autoShiftConn = nil
MotorcycleHUD.ShiftMode = "Auto"
MotorcycleHUD.lastDisplayedRPM = 0
MotorcycleHUD.ShiftModeButton = nil
MotorcycleHUD.lastDisplayedSpeed = 0
MotorcycleHUD.lastComputedGear = "N"
MotorcycleHUD.HelmetTelemetryEvent = nil
MotorcycleHUD.lastTelemetryFire = 0
MotorcycleHUD.telemetryMinInterval = 1 / 60
MotorcycleHUD.interfaceSuppression = nil
MotorcycleHUD.interfaceWatcherConn = nil
MotorcycleHUD.interfaceSuppressLogPrinted = false
MotorcycleHUD.globalGuiSuppression = nil
MotorcycleHUD.coreGuiStates = nil

function MotorcycleHUD:ClearTelemetrySources()
	self.InterfaceGui = nil
	self.ValuesFolder = nil
	self.RPMValue = nil
	self.GearValue = nil
	self.SpeedValue = nil
	self.AutoShiftValue = nil
	if self.autoShiftConn then
		self.autoShiftConn:Disconnect()
		self.autoShiftConn = nil
	end
end

function MotorcycleHUD:ResolveTelemetrySources()
	local interfaceGui = playerGui:FindFirstChild("Interface")
	if interfaceGui ~= self.InterfaceGui then
		if Logger then Logger.Info("HUD", "ResolveTelemetry", { reason = "Interface GUI changed" }) end
		self.InterfaceGui = interfaceGui
		self.ValuesFolder = nil
		self.RPMValue = nil
		self.GearValue = nil
		self.SpeedValue = nil
	end

	if not interfaceGui or not interfaceGui:IsA("ScreenGui") then
		if Logger then Logger.Warn("HUD", "ResolveTelemetry", { reason = "Interface GUI not found" }) end
		return
	end

	if not self.ValuesFolder or not self.ValuesFolder.Parent then
		local valuesFolder = interfaceGui:FindFirstChild("Values")
		if valuesFolder and valuesFolder:IsA("Folder") then
			if Logger then Logger.Info("HUD", "ResolveTelemetry", { reason = "Found Values folder" }) end
			self.ValuesFolder = valuesFolder
		else
			if Logger then Logger.Warn("HUD", "ResolveTelemetry", { reason = "Values folder not found" }) end
			self.ValuesFolder = nil
			self.RPMValue = nil
			self.GearValue = nil
			self.SpeedValue = nil
			return
		end
	end

	if self.ValuesFolder then
		local valuesFolder = self.ValuesFolder
		self.RPMValue = valuesFolder:FindFirstChild("RPM")
			or valuesFolder:FindFirstChild("EngineRPM")
			or valuesFolder:FindFirstChild("DisplayedRPM")
			or valuesFolder:FindFirstChild("ClutchRPM")

		if not self.RPMValue and Logger then
			Logger.Warn("HUD", "ResolveTelemetry", { reason = "RPMValue not found" })
		end

		self.GearValue = valuesFolder:FindFirstChild("Gear")
			or valuesFolder:FindFirstChild("CurrentGear")
			or valuesFolder:FindFirstChild("GearValue")
			or valuesFolder:FindFirstChild("GearDisplay")

		if not self.GearValue and Logger then
			Logger.Warn("HUD", "ResolveTelemetry", { reason = "GearValue not found" })
		end

		self.SpeedValue = valuesFolder:FindFirstChild("Speed")
			or valuesFolder:FindFirstChild("KMH")
			or valuesFolder:FindFirstChild("KPH")
			or valuesFolder:FindFirstChild("SPS")

		local autoShiftValue = valuesFolder:FindFirstChild("AutoShift")
			or valuesFolder:FindFirstChild("AutoMode")
			or valuesFolder:FindFirstChild("ShiftMode")
			or valuesFolder:FindFirstChild("TransmissionMode")
		self:attachAutoShiftValue(autoShiftValue)
	end
end

-- Function to disable old motorcycle Interface GUI (visual elements only)
function MotorcycleHUD:DisableOldGUI()
	local interfaceGui = playerGui:FindFirstChild("Interface")
	if interfaceGui then
		local suppression = self.interfaceSuppression
		if not suppression or suppression.gui ~= interfaceGui then
			if suppression then
				self:RestoreOldGUI()
			end

			suppression = {
				gui = interfaceGui,
				originalEnabled = interfaceGui.Enabled,
				originalDisplayOrder = interfaceGui.DisplayOrder,
				visibilityState = {},
				scriptStates = {},
				connections = {},
			}
			self.interfaceSuppression = suppression
		end

		-- Scripts to KEEP enabled (critical for driving)
		local keepEnabled = {
			["Drive"] = true,
			["Wheelie"] = true,
			["AC6_Sounds"] = true,
			["Anims"] = true,
			["Kickstand"] = true,
		}

		-- Hide the visual Interface GUI (and keep it hidden if other scripts flip it back)
		interfaceGui.DisplayOrder = -1000
		interfaceGui.Enabled = false
		if not self.interfaceSuppressLogPrinted then
			print("🚫 Hiding old motorcycle Interface GUI (keeping drive systems active)")
			if Logger then Logger.Info("GUI", "HideLegacyInterface") end
			self.interfaceSuppressLogPrinted = true
		end

		if suppression.connections.enabledChanged then
			suppression.connections.enabledChanged:Disconnect()
		end
		suppression.connections.enabledChanged = interfaceGui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if self.ScreenGui and self.ScreenGui.Enabled and interfaceGui.Enabled then
				interfaceGui.Enabled = false
			end
		end)

		if suppression.connections.descendantAdded then
			suppression.connections.descendantAdded:Disconnect()
		end
		suppression.connections.descendantAdded = interfaceGui.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("GuiObject") then
				if suppression.visibilityState[descendant] == nil then
					suppression.visibilityState[descendant] = descendant.Visible
				end
				descendant.Visible = false
			elseif descendant:IsA("LocalScript") then
				local firstTime = suppression.scriptStates[descendant] == nil
				if firstTime then
					suppression.scriptStates[descendant] = descendant.Enabled
				end

				if descendant.Enabled and not keepEnabled[descendant.Name] then
					descendant.Enabled = false
					if firstTime then
						print(string.format("   📴 Disabled script: %s", descendant.Name))
						if Logger then Logger.Info("GUI", "DisableScript", { name = descendant.Name }) end
					end
				elseif keepEnabled[descendant.Name] then
					if firstTime then
						print(string.format("   ✓ Kept active: %s", descendant.Name))
						if Logger then Logger.Info("GUI", "KeepScript", { name = descendant.Name }) end
					end
				end
			end
		end)

		for _, descendant in ipairs(interfaceGui:GetDescendants()) do
			if descendant:IsA("GuiObject") then
				if suppression.visibilityState[descendant] == nil then
					suppression.visibilityState[descendant] = descendant.Visible
				end
				descendant.Visible = false
			end

			if descendant:IsA("LocalScript") then
				local firstTime = suppression.scriptStates[descendant] == nil
				if firstTime then
					suppression.scriptStates[descendant] = descendant.Enabled
				end

				if descendant.Enabled and not keepEnabled[descendant.Name] then
					descendant.Enabled = false
					if firstTime then
						print(string.format("   📴 Disabled script: %s", descendant.Name))
						if Logger then Logger.Info("GUI", "DisableScript", { name = descendant.Name }) end
					end
				elseif keepEnabled[descendant.Name] then
					if firstTime then
						print(string.format("   ✓ Kept active: %s", descendant.Name))
						if Logger then Logger.Info("GUI", "KeepScript", { name = descendant.Name }) end
					end
				end
			end
		end
	end

	self:ResolveTelemetrySources()
end

function MotorcycleHUD:EnsureInterfaceWatcher()
	if self.interfaceWatcherConn then
		return
	end

	self.interfaceWatcherConn = playerGui.ChildAdded:Connect(function(child)
		if child.Name ~= "Interface" or not child:IsA("ScreenGui") then
			return
		end

		task.defer(function()
			self:DisableOldGUI()
		end)
	end)

	task.defer(function()
		if playerGui:FindFirstChild("Interface") then
			self:DisableOldGUI()
		end
	end)
end

function MotorcycleHUD:RestoreOldGUI()
	local suppression = self.interfaceSuppression
	if not suppression then
		return
	end

	local interfaceGui = suppression.gui
	if suppression.connections.enabledChanged then
		suppression.connections.enabledChanged:Disconnect()
		suppression.connections.enabledChanged = nil
	end
	if suppression.connections.descendantAdded then
		suppression.connections.descendantAdded:Disconnect()
		suppression.connections.descendantAdded = nil
	end
	suppression.connections = nil

	if interfaceGui and interfaceGui.Parent then
		if suppression.originalDisplayOrder ~= nil then
			interfaceGui.DisplayOrder = suppression.originalDisplayOrder
		end
		if suppression.originalEnabled ~= nil then
			interfaceGui.Enabled = suppression.originalEnabled
		end

		for descendant, wasVisible in pairs(suppression.visibilityState) do
			if descendant and descendant.Parent then
				descendant.Visible = wasVisible
			end
		end

		for scriptInstance, wasEnabled in pairs(suppression.scriptStates) do
			if scriptInstance and scriptInstance.Parent then
				scriptInstance.Enabled = wasEnabled
			end
		end
	end

	suppression.visibilityState = nil
	suppression.scriptStates = nil
	suppression.gui = nil
	self.interfaceSuppression = nil
    self.interfaceSuppressLogPrinted = false
end

function MotorcycleHUD:attachAutoShiftValue(valueObject)
	if self.AutoShiftValue == valueObject then
		return
	end

	if self.autoShiftConn then
		self.autoShiftConn:Disconnect()
		self.autoShiftConn = nil
	end

	self.AutoShiftValue = valueObject
	if valueObject then
		self.autoShiftConn = valueObject.Changed:Connect(function()
			self:UpdateShiftModeFromTelemetry()
		end)
		self:UpdateShiftModeFromTelemetry()
	end
end

function MotorcycleHUD:PushShiftModeToTelemetry()
	local valueObject = self.AutoShiftValue
	if not valueObject or not valueObject.Parent then
		return
	end

	local isAuto = self.ShiftMode == "Auto"
	if valueObject:IsA("BoolValue") then
		valueObject.Value = isAuto
	elseif valueObject:IsA("StringValue") then
		valueObject.Value = isAuto and "Auto" or "Manual"
	elseif valueObject:IsA("IntValue") or valueObject:IsA("NumberValue") then
		valueObject.Value = isAuto and 1 or 0
	end
end

function MotorcycleHUD:UpdateShiftModeFromTelemetry()
	local valueObject = self.AutoShiftValue
	if not valueObject or not valueObject.Parent then
		return
	end

	local mode
	if valueObject:IsA("BoolValue") then
		mode = valueObject.Value and "Auto" or "Manual"
	elseif valueObject:IsA("StringValue") then
		local lower = string.lower(valueObject.Value)
		if lower == "manual" or lower == "man" then
			mode = "Manual"
		else
			mode = "Auto"
		end
	elseif valueObject:IsA("IntValue") or valueObject:IsA("NumberValue") then
		mode = (valueObject.Value or 0) ~= 0 and "Auto" or "Manual"
	end

	if mode and mode ~= self.ShiftMode then
		self:SetShiftMode(mode, false)
	end
end

function MotorcycleHUD:SetShiftMode(nextMode, pushTelemetry)
	local resolvedMode = nextMode == "Manual" and "Manual" or "Auto"
	local previousMode = self.ShiftMode
	self.ShiftMode = resolvedMode

	if self.ShiftModeButton then
		local isAuto = resolvedMode == "Auto"
		self.ShiftModeButton.Text = isAuto and "AUTO" or "MANUAL"
		self.ShiftModeButton.BackgroundColor3 = isAuto and Color3.fromRGB(70, 140, 255) or Color3.fromRGB(255, 120, 60)
	end

	if pushTelemetry ~= false then
		self:PushShiftModeToTelemetry()
	end

	if resolvedMode ~= previousMode then
		print(string.format("⚙️ Shifter mode: %s", resolvedMode))
	end
end

function MotorcycleHUD:Create()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MotorcycleHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false -- Hidden until on bike
	screenGui.DisplayOrder = 15 -- Below HelmetOverlay (20), above most legacy UIs
	screenGui.Parent = playerGui
	
	-- Main HUD Container (Bottom Center, smaller and more compact)
	local hudFrame = Instance.new("Frame")
	hudFrame.Name = "HUDFrame"
	hudFrame.Size = UDim2.new(0, 350, 0, 180)
	hudFrame.Position = UDim2.new(0.5, -175, 1, -200)
	hudFrame.AnchorPoint = Vector2.new(0.5, 0)
	hudFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	hudFrame.BackgroundTransparency = 0.35
	hudFrame.BorderSizePixel = 0
	hudFrame.Parent = screenGui
	
	local hudCorner = Instance.new("UICorner")
	hudCorner.CornerRadius = UDim.new(0, 16)
	hudCorner.Parent = hudFrame
	
	local hudStroke = Instance.new("UIStroke")
	hudStroke.Color = Color3.fromRGB(255, 70, 50)
	hudStroke.Thickness = 2
	hudStroke.Transparency = 0.65
	hudStroke.Parent = hudFrame
	
	-- Speedometer (Left side)
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedLabel"
	speedLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
	speedLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "0"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextSize = 44
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Parent = hudFrame
	
	local speedUnit = Instance.new("TextLabel")
	speedUnit.Size = UDim2.new(0, 60, 0, 20)
	speedUnit.Position = UDim2.new(0.05, 0, 0.55, 0)
	speedUnit.BackgroundTransparency = 1
	speedUnit.Text = "KM/H"
	speedUnit.TextColor3 = Color3.fromRGB(180, 180, 180)
	speedUnit.TextSize = 16
	speedUnit.Font = Enum.Font.Gotham
	speedUnit.Parent = hudFrame
	
	-- Gear Indicator (Center, large)
	local gearLabel = Instance.new("TextLabel")
	gearLabel.Name = "GearLabel"
	gearLabel.Size = UDim2.new(0.25, 0, 0.6, 0)
	gearLabel.Position = UDim2.new(0.375, 0, 0.1, 0)
	gearLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	gearLabel.BackgroundTransparency = 0.4
	gearLabel.Text = "N"
	gearLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	gearLabel.TextSize = 44
	gearLabel.Font = Enum.Font.GothamBold
	gearLabel.Parent = hudFrame
	
	local gearCorner = Instance.new("UICorner")
	gearCorner.CornerRadius = UDim.new(0, 8)
	gearCorner.Parent = gearLabel
	
	-- RPM Bar (Right side)
	local rpmLabel = Instance.new("TextLabel")
	rpmLabel.Name = "RPMLabel"
	rpmLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
	rpmLabel.Position = UDim2.new(0.6, 0, 0.1, 0)
	rpmLabel.BackgroundTransparency = 1
	rpmLabel.Text = "0"
	rpmLabel.TextColor3 = Color3.fromRGB(255, 100, 50)
	rpmLabel.TextSize = 44
	rpmLabel.Font = Enum.Font.GothamBold
	rpmLabel.Parent = hudFrame
	
	local rpmUnit = Instance.new("TextLabel")
	rpmUnit.Size = UDim2.new(0, 60, 0, 20)
	rpmUnit.Position = UDim2.new(0.6, 0, 0.55, 0)
	rpmUnit.BackgroundTransparency = 1
	rpmUnit.Text = "RPM"
	rpmUnit.TextColor3 = Color3.fromRGB(180, 180, 180)
	rpmUnit.TextSize = 16
	rpmUnit.Font = Enum.Font.Gotham
	rpmUnit.Parent = hudFrame
	
	-- Traction Control Indicator (Bottom left, compact)
	local tcButton = Instance.new("TextButton")
	tcButton.Name = "TCButton"
	tcButton.Size = UDim2.new(0, 100, 0, 40)
	tcButton.Position = UDim2.new(0.05, 0, 0.75, 0)
	tcButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	tcButton.BorderSizePixel = 0
	tcButton.Text = "TC ON"
	tcButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	tcButton.TextSize = 18
	tcButton.Font = Enum.Font.GothamBold
	tcButton.AutoButtonColor = false
	tcButton.Parent = hudFrame
	
	local tcCorner = Instance.new("UICorner")
	tcCorner.CornerRadius = UDim.new(0, 6)
	tcCorner.Parent = tcButton
	
	-- Wheelie Button (Bottom center, compact)
	local wheelieButton = Instance.new("TextButton")
	wheelieButton.Name = "WheelieButton"
	wheelieButton.Size = UDim2.new(0, 100, 0, 40)
	wheelieButton.Position = UDim2.new(0, 120, 0, 78)
	wheelieButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	wheelieButton.BorderSizePixel = 0
	wheelieButton.Text = "WHEELIE"
	wheelieButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	wheelieButton.TextSize = 18
	wheelieButton.Font = Enum.Font.GothamBold
	wheelieButton.Parent = hudFrame
	
	local wheelieCorner = Instance.new("UICorner")
	wheelieCorner.CornerRadius = UDim.new(0, 6)
	wheelieCorner.Parent = wheelieButton
	
	-- Shift Mode Button (Bottom right, compact)
	local shiftModeButton = Instance.new("TextButton")
	shiftModeButton.Name = "ShiftModeButton"
	shiftModeButton.Size = UDim2.new(0, 100, 0, 40)
	shiftModeButton.Position = UDim2.new(1, -110, 0.75, 0)
	shiftModeButton.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
	shiftModeButton.BorderSizePixel = 0
	shiftModeButton.Text = "AUTO"
	shiftModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shiftModeButton.TextSize = 18
	shiftModeButton.Font = Enum.Font.GothamBold
	shiftModeButton.Parent = hudFrame
	
	local shiftCorner = Instance.new("UICorner")
	shiftCorner.CornerRadius = UDim.new(0, 6)
	shiftCorner.Parent = shiftModeButton
	
	-- Event handlers
	tcButton.MouseButton1Click:Connect(function()
		self:ToggleTractionControl()
	end)
	
	shiftModeButton.MouseButton1Click:Connect(function()
		self:ToggleShiftMode()
	end)
	
	self.ScreenGui = screenGui
	self.SpeedLabel = speedLabel
	self.GearLabel = gearLabel
	self.RPMLabel = rpmLabel
	self.TCButton = tcButton
	self.ShiftModeButton = shiftModeButton
	
	print("✓ Motorcycle HUD UI created")
end

function MotorcycleHUD:Update(seat, bike)
	self:ResolveTelemetrySources()

	local rpm = self.RPMValue and self.RPMValue.Value or 0
	local speed = self.SpeedValue and self.SpeedValue.Value or 0
	local gear = self.GearValue and self.GearValue.Value or "N"
	local throttle = seat.Throttle
	local steer = seat.Steer

	-- Update UI
	if self.ScreenGui and self.ScreenGui.Enabled then
		local displayedRPM = math.floor(rpm / 100) * 100
		if displayedRPM ~= self.lastDisplayedRPM then
			self.RPMLabel.Text = tostring(displayedRPM)
			self.lastDisplayedRPM = displayedRPM
		end

		local displayedSpeed = math.floor(speed)
		if displayedSpeed ~= self.lastDisplayedSpeed then
			self.SpeedLabel.Text = tostring(displayedSpeed)
			self.lastDisplayedSpeed = displayedSpeed
		end

		if gear ~= self.lastComputedGear then
			self.GearLabel.Text = tostring(gear)
			if gear == "N" or gear == 0 then
				self.GearLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			elseif rpm > ENGINE_REDLINE_RPM * 0.9 then
				self.GearLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			else
				self.GearLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
			self.lastComputedGear = gear
		end
	end

	-- Fire telemetry event for other scripts
	local now = tick()
	if self.HelmetTelemetryEvent and (now - self.lastTelemetryFire > self.telemetryMinInterval) then
		self.lastTelemetryFire = now
		self.HelmetTelemetryEvent:Fire({
			rpm = rpm,
			engineRpm = rpm,
			speed = speed,
			gear = gear,
			throttle = throttle,
			steer = steer,
			isMounted = true,
			TractionControl = self.TractionControl,
			ShiftMode = self.ShiftMode,
			bike = bike,
			seat = seat,
		})
	end

	-- Send telemetry data
	local telemetryData = {
		rpm = (self.RPMValue and self.RPMValue.Value) or 0,
		throttle = (self.ThrottleValue and self.ThrottleValue.Value) or 0,
		gear = (self.GearValue and self.GearValue.Value) or "N",
		speed = speed,
		hasRaw = self.RPMValue ~= nil,
		hasSeatThrottle = self.ThrottleValue ~= nil,
	}

	if self.RPMValue then
		Logger.Info("HUD", "RPM_DEBUG", { raw_rpm = self.RPMValue.Value, type = type(self.RPMValue.Value) })
	end

	self.TelemetryEvent:Fire(telemetryData)

	-- Update HUD elements
end

function MotorcycleHUD:Start(seat, bike)
	if self.CurrentSeat == seat then
		return
	end

	print("▶️ Starting Motorcycle HUD")
	self:Stop()

	self.CurrentBike = bike
	self.CurrentSeat = seat
	self.ScreenGui.Enabled = true

	self:ResolveTelemetrySources()
	self:EnsureInterfaceWatcher()
	self:UpdateShiftModeFromTelemetry()

	self.runConn = RunService.Heartbeat:Connect(function()
		self:Update(seat, bike)
	end)

	if Logger then
		Logger.Info("HUD", "Start", { bike = bike and bike.Name, seat = seat and seat.Name })
	end
end

function MotorcycleHUD:Stop()
	if not self.CurrentSeat then
		return
	end

	print("⏹️ Stopping Motorcycle HUD")

	if self.runConn then
		self.runConn:Disconnect()
		self.runConn = nil
	end

	if self.ScreenGui then
		self.ScreenGui.Enabled = false
	end

	if self.HelmetTelemetryEvent then
		self.HelmetTelemetryEvent:Fire({ isMounted = false })
	end

	self:RestoreOldGUI()
	self:ClearTelemetrySources()

	if Logger then
		Logger.Info("HUD", "Stop")
	end

	self.CurrentSeat = nil
	self.CurrentBike = nil
	if self.ScreenGui then
		self.ScreenGui.Enabled = false
	end
end

function MotorcycleHUD:Initialize()
	self:Create()
	self.HelmetTelemetryEvent = Instance.new("BindableEvent")
	self.HelmetTelemetryEvent.Name = "HelmetTelemetry"
	self.HelmetTelemetryEvent.Parent = playerGui

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self:ConnectSeat(humanoid)
	end
	player.CharacterAdded:Connect(function(char)
		humanoid = char:WaitForChild("Humanoid")
		self:ConnectSeat(humanoid)
	end)

	if Logger then Logger.Info("HUD", "Initialized") end
	print("✓ Motorcycle HUD initialized")
end

-- Function to disable old motorcycle Interface GUI
function MotorcycleHUD:SuppressOldInterface(suppress)
	local playerGui = self.PlayerGui
	if not playerGui then return end

	local interfaceGui = playerGui:FindFirstChild("Interface")
	if interfaceGui then
		if suppress then
			if not self.interfaceSuppressLogPrinted then
				if Logger then Logger.Info("HUD", "Suppress", { suppressed = true, reason = "Surgically disabling legacy Interface GUI" }) end
				self.interfaceSuppressLogPrinted = true -- Log only once
			end

			-- Disable all visual elements and scripts, but leave "Values" folder
			for _, child in ipairs(interfaceGui:GetChildren()) do
				if child.Name ~= "Values" then
					if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
						child.Visible = false
					elseif child:IsA("Script") or child:IsA("LocalScript") then
						child.Disabled = true
					end
				end
			end
		end
	end
end

return MotorcycleHUD
