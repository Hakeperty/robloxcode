-- StartMenuGUI.lua
-- Main menu with play button and bike selection

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StartMenuGUI = {}

function StartMenuGUI:Create()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StartMenuGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Main Menu Frame (covers whole screen)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 600, 0, 100)
	title.Position = UDim2.new(0.5, -300, 0.25, 0)
	title.BackgroundTransparency = 1
	title.Text = "BIKE RACING"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 72
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Play Button
	local playButton = Instance.new("TextButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.new(0, 300, 0, 80)
	playButton.Position = UDim2.new(0.5, -150, 0.5, -40)
	playButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	playButton.BorderSizePixel = 0
	playButton.Text = "PLAY"
	playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	playButton.TextSize = 48
	playButton.Font = Enum.Font.GothamBold
	playButton.AutoButtonColor = true
	playButton.Parent = mainFrame
	
	-- Button hover effect
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = playButton
	
	-- Bike Selection Frame (initially hidden)
	local bikeSelectionFrame = Instance.new("Frame")
	bikeSelectionFrame.Name = "BikeSelectionFrame"
	bikeSelectionFrame.Size = UDim2.new(1, 0, 1, 0)
	bikeSelectionFrame.Position = UDim2.new(0, 0, 0, 0)
	bikeSelectionFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	bikeSelectionFrame.BorderSizePixel = 0
	bikeSelectionFrame.Visible = false
	bikeSelectionFrame.Parent = screenGui
	
	-- Bike Selection Title
	local selectionTitle = Instance.new("TextLabel")
	selectionTitle.Name = "SelectionTitle"
	selectionTitle.Size = UDim2.new(0, 600, 0, 80)
	selectionTitle.Position = UDim2.new(0.5, -300, 0.1, 0)
	selectionTitle.BackgroundTransparency = 1
	selectionTitle.Text = "SELECT YOUR BIKE"
	selectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectionTitle.TextSize = 56
	selectionTitle.Font = Enum.Font.GothamBold
	selectionTitle.Parent = bikeSelectionFrame
	
	-- Bikes Container
	local bikesContainer = Instance.new("ScrollingFrame")
	bikesContainer.Name = "BikesContainer"
	bikesContainer.Size = UDim2.new(0.8, 0, 0.6, 0)
	bikesContainer.Position = UDim2.new(0.1, 0, 0.25, 0)
	bikesContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	bikesContainer.BorderSizePixel = 0
	bikesContainer.ScrollBarThickness = 10
	bikesContainer.Parent = bikeSelectionFrame
	
	local bikesCorner = Instance.new("UICorner")
	bikesCorner.CornerRadius = UDim.new(0, 12)
	bikesCorner.Parent = bikesContainer
	
	-- Grid Layout for bikes
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 300, 0, 200)
	gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = bikesContainer
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = bikesContainer
	
	-- Play button click handler
	playButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		bikeSelectionFrame.Visible = true
		self:PopulateBikes(bikesContainer)
	end)
	
	return screenGui
end

function StartMenuGUI:PopulateBikes(container)
	-- Clear existing bikes
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
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
		noBikesLabel.Position = UDim2.new(0, 0, 0.4, 0)
		noBikesLabel.BackgroundTransparency = 1
		noBikesLabel.Text = "No bikes available!\nAdd bikes to ReplicatedStorage/Vehicles"
		noBikesLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		noBikesLabel.TextSize = 24
		noBikesLabel.Font = Enum.Font.Gotham
		noBikesLabel.Parent = container
		return
	end
	
	-- Create bike selection buttons
	for _, bike in pairs(bikes) do
		if bike:IsA("Model") then
			self:CreateBikeButton(bike, container)
		end
	end
	
	-- Update canvas size
	container.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#bikes / 3) * 220 + 40)
end

function StartMenuGUI:CreateBikeButton(bikeModel, parent)
	local bikeFrame = Instance.new("Frame")
	bikeFrame.Name = bikeModel.Name
	bikeFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	bikeFrame.BorderSizePixel = 0
	bikeFrame.Parent = parent
	
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = bikeFrame
	
	-- Bike Name
	local bikeNameLabel = Instance.new("TextLabel")
	bikeNameLabel.Size = UDim2.new(1, -20, 0, 40)
	bikeNameLabel.Position = UDim2.new(0, 10, 0, 10)
	bikeNameLabel.BackgroundTransparency = 1
	bikeNameLabel.Text = bikeModel.Name
	bikeNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bikeNameLabel.TextSize = 18
	bikeNameLabel.Font = Enum.Font.GothamBold
	bikeNameLabel.TextWrapped = true
	bikeNameLabel.TextScaled = true
	bikeNameLabel.Parent = bikeFrame
	
	-- Select Button
	local selectButton = Instance.new("TextButton")
	selectButton.Name = "SelectButton"
	selectButton.Size = UDim2.new(0.8, 0, 0, 50)
	selectButton.Position = UDim2.new(0.1, 0, 0.65, 0)
	selectButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	selectButton.BorderSizePixel = 0
	selectButton.Text = "SELECT"
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.TextSize = 24
	selectButton.Font = Enum.Font.GothamBold
	selectButton.AutoButtonColor = true
	selectButton.Parent = bikeFrame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = selectButton
	
	-- Button click handler
	selectButton.MouseButton1Click:Connect(function()
		self:SpawnPlayerOnBike(bikeModel.Name)
	end)
end

function StartMenuGUI:SpawnPlayerOnBike(bikeName)
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local spawnVehicleEvent = remoteEvents:WaitForChild("SpawnVehicle")
	
	-- Request bike spawn from server
	spawnVehicleEvent:FireServer(bikeName)
	
	-- Hide GUI
	local screenGui = playerGui:FindFirstChild("StartMenuGUI")
	if screenGui then
		screenGui.Enabled = false
	end
	
	print("Requested spawn on bike: " .. bikeName)
end

-- Initialize
StartMenuGUI:Create()

return StartMenuGUI
