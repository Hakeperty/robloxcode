-- Monitors all GUI scripts and elements on the client side

-- Verbosity control: default to verbose in Studio, quiet otherwise; override via DebugConfig and/or ReplicatedStorage attribute
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local verbose = RunService:IsStudio()
do
	local ok, DebugConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DebugConfig"))
	end)
	if ok and type(DebugConfig) == "table" and DebugConfig.BikeGUI and type(DebugConfig.BikeGUI.MonitorVerbose) == "boolean" then
		verbose = DebugConfig.BikeGUI.MonitorVerbose
	end
	-- Attribute toggle (optional): game.ReplicatedStorage:SetAttribute("BikeGUIMonitorVerbose", true/false)
	local attr = ReplicatedStorage:GetAttribute("BikeGUIMonitorVerbose")
	if type(attr) == "boolean" then
		verbose = attr
	end
	ReplicatedStorage:GetAttributeChangedSignal("BikeGUIMonitorVerbose"):Connect(function()
		local v = ReplicatedStorage:GetAttribute("BikeGUIMonitorVerbose")
		if type(v) == "boolean" then
			verbose = v
		end
	end)
end

local function vprint(...)
	if verbose then
		print(...)
	end
end

vprint("🔍 === Client-Side Bike GUI Monitor Starting ===")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Track what GUI elements exist
local trackedGuis = {}

-- Monitor PlayerGui for all additions
playerGui.DescendantAdded:Connect(function(descendant)
	local parentName = descendant.Parent and descendant.Parent.Name or "Unknown"
	
	-- Log all GUI elements (especially bike-related)
	if descendant:IsA("GuiObject") or descendant:IsA("ScreenGui") then
		vprint(string.format("🖥️ [GUI ADDED] %s | Parent: %s | Type: %s", 
			descendant.Name, 
			parentName,
			descendant.ClassName))
		
		-- Track Interface GUI specifically (the bike's existing GUI)
		if parentName == "Interface" or descendant.Name == "Interface" then
			vprint(string.format("   ⚠️ [BIKE GUI] This is from the motorcycle's Interface system!"))
			vprint(string.format("      Path: %s", descendant:GetFullName():gsub("Players%." .. player.Name .. "%.PlayerGui%.", "")))
			trackedGuis[descendant] = true
		end
	end
	
	-- Log all scripts
	if descendant:IsA("LocalScript") or descendant:IsA("Script") then
		vprint(string.format("📜 [CLIENT SCRIPT ADDED] %s | Parent: %s | Enabled: %s", 
			descendant.Name,
			parentName,
			tostring(descendant.Enabled)))
		vprint(string.format("   Path: %s", descendant:GetFullName():gsub("Players%." .. player.Name .. "%.", "")))
	elseif descendant:IsA("ModuleScript") then
		vprint(string.format("📜 [CLIENT MODULE ADDED] %s | Parent: %s", 
			descendant.Name,
			parentName))
		vprint(string.format("   Path: %s", descendant:GetFullName():gsub("Players%." .. player.Name .. "%.", "")))
	end
end)

local currentBike = nil

game:GetService("RunService").Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	-- Check if on a VehicleSeat
	if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
		local bike = humanoid.SeatPart.Parent
		
		-- If this is a new bike, log it
		if bike and bike ~= currentBike then
			currentBike = bike
			vprint(string.format("🏍️ [PLAYER MOUNTED BIKE] %s", bike.Name))
			
			-- List all scripts in the bike
			vprint("   📊 [BIKE SCRIPTS] Scanning for active scripts...")
			for _, descendant in ipairs(bike:GetDescendants()) do
				if (descendant:IsA("Script") or descendant:IsA("LocalScript")) and descendant.Enabled then
					vprint(string.format("      📜 Active: %s | Type: %s | Path: %s", 
						descendant.Name,
						descendant.ClassName,
						descendant:GetFullName():gsub("Workspace%.", "")))
				elseif descendant:IsA("ModuleScript") then
					vprint(string.format("      📦 Module: %s | Path: %s", 
						descendant.Name,
						descendant:GetFullName():gsub("Workspace%.", "")))
				end
			end
			
			-- Check for GUI that gets added
			task.wait(0.5)
			vprint("   🖥️ [CHECKING PLAYERGUI] Looking for bike-related GUI...")
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui.Name == "Interface" or gui.Name:find("Bike") or gui.Name:find("Motor") then
					local guiEnabled = gui:IsA("ScreenGui") and tostring(gui.Enabled) or "n/a"
					vprint(string.format("      ⚠️ Found: %s | Enabled: %s", gui.Name, guiEnabled))
					
					-- List all descendants
					for _, element in ipairs(gui:GetDescendants()) do
						if element:IsA("LocalScript") then
							vprint(string.format("         📜 Script: %s | Enabled: %s", element.Name, tostring(element.Enabled)))
						elseif element:IsA("Frame") or element:IsA("TextLabel") then
							vprint(string.format("         🖼️ Element: %s | Type: %s | Visible: %s", 
								element.Name, 
								element.ClassName,
								tostring(element.Visible)))
						end
					end
				end
			end
		end
	else
		-- Not on bike anymore
		if currentBike then
			vprint(string.format("📴 [PLAYER LEFT BIKE] %s", currentBike.Name))
			currentBike = nil
		end
	end
end)

task.wait(2)
vprint("📋 [EXISTING GUI SCAN] Listing all PlayerGui contents:")
for _, gui in ipairs(playerGui:GetChildren()) do
	local enabledInfo = "n/a"
	if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
		enabledInfo = tostring(gui.Enabled)
	end
	vprint(string.format("   🖥️ %s | Type: %s | Enabled: %s", gui.Name, gui.ClassName, enabledInfo))
	
	-- Count children
	local scriptCount = 0
	local frameCount = 0
	for _, child in ipairs(gui:GetDescendants()) do
		if child:IsA("LocalScript") or child:IsA("ModuleScript") then
			scriptCount = scriptCount + 1
		elseif child:IsA("Frame") or child:IsA("GuiObject") then
			frameCount = frameCount + 1
		end
	end
	
	if scriptCount > 0 or frameCount > 0 then
		vprint(string.format("      └─ Contains: %d scripts, %d GUI elements", scriptCount, frameCount))
	end
end

vprint("✓ Client-Side Bike GUI Monitor Active")
