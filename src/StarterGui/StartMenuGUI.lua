-- StartMenuGUI.lua
-- Main menu with play button and bike selection
-- Redesigned for a modern and clean look

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Logger
pcall(function()
	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	if Modules then
		Logger = require(Modules:FindFirstChild("ClientLogger"))
	end
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StartMenuGUI = {}

-- Animation helpers
local function tween(instance, property, value, duration, easingStyle, easingDirection)
	if not instance then
		return nil
	end

	-- Non-tweenable values (like booleans) get applied directly
	if typeof(value) == "boolean" then
		instance[property] = value
		return nil
	end

	local info = TweenInfo.new(duration, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
	local goal = {}
	goal[property] = value

	local ok, tweenObj = pcall(function()
		return TweenService:Create(instance, info, goal)
	end)

	if ok then
		return tweenObj
	else
		local instanceName = "<unknown>"
		if typeof(instance) == "Instance" then
			instanceName = instance:GetFullName()
		end
		warn(string.format("[StartMenuGUI] Tween creation failed for %s.%s (%s)", instanceName, tostring(property), tostring(tweenObj)))
		return nil
	end
end

local function playTween(instance, property, value, duration, easingStyle, easingDirection)
	local tweenObj = tween(instance, property, value, duration, easingStyle, easingDirection)
	if tweenObj then
		tweenObj:Play()
	end
end

function StartMenuGUI:Create()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StartMenuScreen"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self.screenGui = screenGui
	
	-- Main Menu Frame (covers whole screen)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	self.mainFrame = mainFrame
	
	-- Add gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 30, 36)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 19, 23))
	}
	gradient.Rotation = 90
	gradient.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -80, 0, 120)
	title.Position = UDim2.new(0.5, 0, 0.3, -60)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = "MOTO MADNESS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 90
	title.Font = Enum.Font.GothamBlack
	title.TextStrokeTransparency = 0.8
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.Parent = mainFrame
	
	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -80, 0, 40)
	subtitle.Position = UDim2.new(0.5, 0, 0.3, 20)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "THE ULTIMATE RIDING EXPERIENCE"
	subtitle.TextColor3 = Color3.fromRGB(150, 155, 165)
	subtitle.TextSize = 22
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Parent = mainFrame

	-- Play Button
	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.new(0, 320, 0, 70)
	playButton.Position = UDim2.new(0.5, 0, 0.6, 0)
	playButton.AnchorPoint = Vector2.new(0.5, 0.5)
	playButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	playButton.BorderSizePixel = 0
	playButton.Text = "SELECT BIKE"
	playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playButton.TextSize = 28
	playButton.Font = Enum.Font.GothamBold
	playButton.AutoButtonColor = false
	playButton.Parent = mainFrame
	self.playButton = playButton
	
	-- Button styling
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = playButton
	
	local buttonShadow = Instance.new("ImageLabel")
	buttonShadow.Name = "Shadow"
	buttonShadow.Size = UDim2.new(1, 10, 1, 10)
	buttonShadow.Position = UDim2.new(0.5, 0, 0.5, 5)
	buttonShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonShadow.BackgroundTransparency = 1
	buttonShadow.Image = "rbxassetid://273390087" -- Blur image
	buttonShadow.ImageColor3 = Color3.fromRGB(0, 80, 180)
	buttonShadow.ImageTransparency = 0.5
	buttonShadow.ScaleType = Enum.ScaleType.Slice
	buttonShadow.SliceCenter = Rect.new(10, 10, 118, 118)
	buttonShadow.ZIndex = 0
	buttonShadow.Parent = playButton
	
	-- Hover animation
	playButton.MouseEnter:Connect(function()
		playTween(playButton, "BackgroundColor3", Color3.fromRGB(0, 140, 255), 0.2)
		playTween(playButton, "Position", UDim2.new(0.5, 0, 0.6, -5), 0.2)
		playTween(buttonShadow, "ImageTransparency", 0.3, 0.2)
	end)

	playButton.MouseLeave:Connect(function()
		playTween(playButton, "BackgroundColor3", Color3.fromRGB(0, 122, 255), 0.2)
		playTween(playButton, "Position", UDim2.new(0.5, 0, 0.6, 0), 0.2)
		playTween(buttonShadow, "ImageTransparency", 0.5, 0.2)
	end)
	
	-- Bike Selection Frame (initially hidden)
	local bikeSelectionFrame = Instance.new("Frame")
	bikeSelectionFrame.Name = "BikeSelectionFrame"
	bikeSelectionFrame.Size = UDim2.new(1, 0, 1, 0)
	bikeSelectionFrame.Position = UDim2.new(0, 0, 1, 0) -- Start off-screen
	bikeSelectionFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
	bikeSelectionFrame.BorderSizePixel = 0
	bikeSelectionFrame.Visible = false
	bikeSelectionFrame.Parent = screenGui
	self.bikeSelectionFrame = bikeSelectionFrame
	
	-- Bike Selection Title
	local selectionTitle = Instance.new("TextLabel")
	selectionTitle.Name = "SelectionTitle"
	selectionTitle.Size = UDim2.new(1, -80, 0, 90)
	selectionTitle.Position = UDim2.new(0.5, 0, 0.1, 0)
	selectionTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	selectionTitle.BackgroundTransparency = 1
	selectionTitle.Text = "CHOOSE YOUR RIDE"
	selectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectionTitle.TextSize = 54
	selectionTitle.Font = Enum.Font.GothamBlack
	selectionTitle.Parent = bikeSelectionFrame
	
	-- Bikes Container
	local bikesContainer = Instance.new("ScrollingFrame")
	bikesContainer.Name = "BikesContainer"
	bikesContainer.Size = UDim2.new(1, -80, 0.7, 0)
	bikesContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
	bikesContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	bikesContainer.BackgroundTransparency = 1
	bikesContainer.BorderSizePixel = 0
	bikesContainer.ScrollBarThickness = 8
	bikesContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 122, 255)
	bikesContainer.Parent = bikeSelectionFrame
	self.bikesContainer = bikesContainer
	
	-- Grid Layout for bikes
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 280, 0, 320)
	gridLayout.CellPadding = UDim2.new(0, 30, 0, 30)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.FillDirectionMaxCells = 3
	gridLayout.Parent = bikesContainer
	self.gridLayout = gridLayout
	
	-- Play button click handler
	playButton.MouseButton1Click:Connect(function()
		if Logger then Logger.Info("StartMenu", "OpenBikeSelection") end
		mainFrame.Visible = false
		bikeSelectionFrame.Visible = true
		playTween(bikeSelectionFrame, "Position", UDim2.new(0, 0, 0, 0), 0.5, Enum.EasingStyle.Quint)
		self:PopulateBikes(bikesContainer)
	end)
	
	return screenGui
end

function StartMenuGUI:ResetSelectionState()
	self.pendingBikeName = nil
	if not self.bikesContainer then
		return
	end

	for _, card in ipairs(self.bikesContainer:GetChildren()) do
		if card:IsA("Frame") then
			local selectButton = card:FindFirstChild("SelectButton")
			if selectButton and selectButton:IsA("TextButton") then
				selectButton.Text = "RIDE"
				selectButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
				selectButton.Active = true
				selectButton.AutoButtonColor = false
			end
		end
	end
end

function StartMenuGUI:HideMenu()
	if Logger then Logger.Info("StartMenu", "Hide") end
	if self.seatConnection then
		self.seatConnection:Disconnect()
		self.seatConnection = nil
	end

	self:ResetSelectionState()

	if self.bikeSelectionFrame then
		self.bikeSelectionFrame.Visible = false
		self.bikeSelectionFrame.Position = UDim2.new(0, 0, 1, 0)
	end

	if self.mainFrame then
		self.mainFrame.Visible = true
	end

	local screenGui = self.screenGui
	if not screenGui or not screenGui:IsA("ScreenGui") then
		screenGui = playerGui:FindFirstChild("StartMenuScreen")
	end

	if screenGui and screenGui:IsA("ScreenGui") then
		screenGui.Enabled = false
		print("✓ GUI hidden")
	else
		warn("[StartMenuGUI] Unable to hide start menu screen")
	end
end

function StartMenuGUI:BeginBikeSpawn(selectedButton, bikeName)
	self.pendingBikeName = bikeName
	if not self.bikesContainer then
		return
	end

	for _, card in ipairs(self.bikesContainer:GetChildren()) do
		if card:IsA("Frame") then
			local selectButton = card:FindFirstChild("SelectButton")
			if selectButton and selectButton:IsA("TextButton") then
				selectButton.Active = false
				if selectButton == selectedButton then
					selectButton.Text = "SPAWNING..."
					selectButton.BackgroundColor3 = Color3.fromRGB(0, 90, 200)
				else
					selectButton.Text = "WAIT..."
					selectButton.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
				end
			end
		end
	end
end

function StartMenuGUI:WaitForSeating(bikeName)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	if not humanoid then
		self:HideMenu()
		return
	end

	if self.seatConnection then
		self.seatConnection:Disconnect()
		self.seatConnection = nil
	end

	local settled = false
	local connection

	local function cleanup(didSeat)
		if settled then
			return
		end
		settled = true
		if connection then
			connection:Disconnect()
		end
		self.seatConnection = nil
		if didSeat then
			self:HideMenu()
		else
			warn("[StartMenuGUI] Timed out waiting for seat confirmation; re-enabling menu.")
			self:ResetSelectionState()
		end
	end

	local function checkSeat()
		if settled then
			return
		end

		local seat = humanoid.SeatPart
		if seat and seat:IsA("VehicleSeat") then
			local seatModel = seat.Parent
			if not bikeName or (seatModel and (seatModel.Name == bikeName or string.find(seatModel.Name, bikeName, 1, true))) then
				cleanup(true)
			end
		end
	end

	connection = humanoid:GetPropertyChangedSignal("SeatPart"):Connect(checkSeat)
	self.seatConnection = connection
	task.defer(checkSeat)

	task.delay(8, function()
		if self.seatConnection == connection then
			cleanup(false)
		end
	end)
end

function StartMenuGUI:PopulateBikes(container)
	self:ResetSelectionState()
	-- Clear existing bikes
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local gridLayout = container:FindFirstChildOfClass("UIGridLayout")
	if not gridLayout then
		warn("[StartMenuGUI] Bikes container missing UIGridLayout")
		return
	end

	-- Get bikes from ReplicatedStorage
	local vehiclesFolder = ReplicatedStorage:FindFirstChild("Vehicles")
	if not vehiclesFolder then
		warn("Vehicles folder not found in ReplicatedStorage")
		return
	end
	
	local bikes = vehiclesFolder:GetChildren()
	
	if #bikes == 0 then
		-- No bikes available message
		local noBikesLabel = Instance.new("TextLabel")
		noBikesLabel.Size = UDim2.new(1, 0, 0, 100)
		noBikesLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		noBikesLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		noBikesLabel.BackgroundTransparency = 1
		noBikesLabel.Text = "No bikes available!"
		noBikesLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		noBikesLabel.TextSize = 24
		noBikesLabel.Font = Enum.Font.GothamBold
		noBikesLabel.Parent = container
		return
	end
	
	-- Create bike selection buttons
	for i, bike in ipairs(bikes) do
		if bike:IsA("Model") then
			local button = self:CreateBikeButton(bike, container)
			button.LayoutOrder = i
		end
	end
	
	-- Update canvas size
	local columns = math.max(gridLayout.FillDirectionMaxCells, 1)
	local rows = math.ceil(#bikes / columns)
	local cellHeight = gridLayout.CellSize.Y.Offset
	local paddingY = gridLayout.CellPadding.Y.Offset
	local totalHeight = rows * cellHeight + math.max(rows - 1, 0) * paddingY + 40
	container.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

function StartMenuGUI:CreateBikeButton(bikeModel, parent)
	local bikeFrame = Instance.new("Frame")
	bikeFrame.Name = bikeModel.Name
	bikeFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
	bikeFrame.BorderSizePixel = 0
	bikeFrame.ClipsDescendants = true
	bikeFrame.Parent = parent
	
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 16)
	frameCorner.Parent = bikeFrame
	
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(45, 48, 56)
	frameStroke.Thickness = 2
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = bikeFrame
	
	-- Bike Viewport
	local bikeViewport = Instance.new("ViewportFrame")
	bikeViewport.Size = UDim2.new(1, 0, 0.65, 0)
	bikeViewport.BackgroundColor3 = Color3.fromRGB(22, 23, 28)
	bikeViewport.BorderSizePixel = 0
	bikeViewport.Ambient = Color3.new(0.5, 0.5, 0.5)
	bikeViewport.LightColor = Color3.new(1, 1, 1)
	bikeViewport.LightDirection = Vector3.new(-1, -1, -1)
	bikeViewport.Parent = bikeFrame

	local viewportCam = Instance.new("Camera")
	viewportCam.Parent = bikeViewport
	bikeViewport.CurrentCamera = viewportCam

	local bikeClone = bikeModel:Clone()

	if not bikeClone.PrimaryPart then
		warn(string.format("[StartMenuGUI] Model '%s' is missing a PrimaryPart. Attempting automatic fix...", bikeClone.Name))
		local largestPart
		local largestMagnitude = -math.huge
		for _, descendant in ipairs(bikeClone:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local magnitude = descendant.Size.Magnitude
				if magnitude > largestMagnitude then
					largestMagnitude = magnitude
					largestPart = descendant
				end
			end
		end

		if largestPart then
			bikeClone.PrimaryPart = largestPart
			print(string.format("[StartMenuGUI] Auto-set PrimaryPart for '%s' to '%s'", bikeClone.Name, largestPart.Name))
		else
			warn(string.format("[StartMenuGUI] Unable to auto-set PrimaryPart for '%s'. Displaying placeholder.", bikeClone.Name))
			local placeholder = Instance.new("TextLabel")
			placeholder.Size = UDim2.new(1, -20, 0, 60)
			placeholder.Position = UDim2.new(0.5, 0, 0.5, 0)
			placeholder.AnchorPoint = Vector2.new(0.5, 0.5)
			placeholder.BackgroundTransparency = 1
			placeholder.Text = "Model preview unavailable\nPrimaryPart missing"
			placeholder.TextColor3 = Color3.fromRGB(255, 100, 100)
			placeholder.TextScaled = true
			placeholder.Font = Enum.Font.GothamBold
			placeholder.Parent = bikeViewport
			return bikeFrame
		end
	end

	for _, descendant in ipairs(bikeClone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		end
	end

	bikeClone.Parent = bikeViewport

	if bikeClone.PrimaryPart then
		bikeClone:SetPrimaryPartCFrame(CFrame.new(0, 0, -8) * CFrame.Angles(0, math.rad(180), 0))
		local _, modelSize = bikeClone:GetBoundingBox()
		viewportCam.CFrame = CFrame.new(Vector3.new(0, modelSize.Y * 0.35, modelSize.Z + 6), Vector3.new(0, modelSize.Y * 0.25, 0))
	end

	-- Bike Name
	local bikeNameLabel = Instance.new("TextLabel")
	bikeNameLabel.Size = UDim2.new(1, -20, 0, 30)
	bikeNameLabel.Position = UDim2.new(0.5, 0, 0.75, 0)
	bikeNameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	bikeNameLabel.BackgroundTransparency = 1
	bikeNameLabel.Text = string.upper(bikeModel.Name)
	bikeNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bikeNameLabel.TextSize = 22
	bikeNameLabel.Font = Enum.Font.GothamBold
	bikeNameLabel.Parent = bikeFrame
	
	-- Select Button
	local selectButton = Instance.new("TextButton")
	selectButton.Name = "SelectButton"
	selectButton.Size = UDim2.new(1, -40, 0, 50)
	selectButton.Position = UDim2.new(0.5, 0, 0.9, 0)
	selectButton.AnchorPoint = Vector2.new(0.5, 0.5)
	selectButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	selectButton.BorderSizePixel = 0
	selectButton.Text = "RIDE"
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.TextSize = 20
	selectButton.Font = Enum.Font.GothamBold
	selectButton.AutoButtonColor = false
	selectButton.ZIndex = 2
	selectButton.Parent = bikeFrame
	selectButton:SetAttribute("BikeName", bikeModel.Name)
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = selectButton
	
	-- Hover effects
	bikeFrame.MouseEnter:Connect(function()
		playTween(frameStroke, "Color", Color3.fromRGB(0, 122, 255), 0.2)
		playTween(frameStroke, "Thickness", 3, 0.2)
	end)

	bikeFrame.MouseLeave:Connect(function()
		playTween(frameStroke, "Color", Color3.fromRGB(45, 48, 56), 0.2)
		playTween(frameStroke, "Thickness", 2, 0.2)
	end)

	selectButton.MouseEnter:Connect(function()
		playTween(selectButton, "BackgroundColor3", Color3.fromRGB(0, 140, 255), 0.2)
	end)

	selectButton.MouseLeave:Connect(function()
		playTween(selectButton, "BackgroundColor3", Color3.fromRGB(0, 122, 255), 0.2)
	end)
	
	-- Button click handler
	selectButton.MouseButton1Click:Connect(function()
		if self.pendingBikeName then
			return
		end
		if Logger then Logger.Info("StartMenu", "SelectBike", { bike = bikeModel.Name }) end
		self:BeginBikeSpawn(selectButton, bikeModel.Name)
		self:SpawnPlayerOnBike(bikeModel.Name)
	end)

	return bikeFrame
end

function StartMenuGUI:SpawnPlayerOnBike(bikeName)
	if Logger then Logger.Info("StartMenu", "SpawnRequest", { bike = bikeName }) end
	print("Attempting to spawn on bike: " .. bikeName)
	
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		warn("RemoteEvents folder not found! Make sure the server scripts are running.")
		self:ResetSelectionState()
		return
	end
	
	local spawnVehicleEvent = remoteEvents:WaitForChild("SpawnVehicle", 5)
	if not spawnVehicleEvent then
		warn("SpawnVehicle RemoteEvent not found!")
		self:ResetSelectionState()
		return
	end
	
	-- Request bike spawn from server
	spawnVehicleEvent:FireServer(bikeName)
	print("✓ Spawn request sent for: " .. bikeName)

	self:WaitForSeating(bikeName)
end

-- Initialize
StartMenuGUI:Create()

return StartMenuGUI
