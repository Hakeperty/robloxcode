-- Logs all parts and scripts activated/used on motorcycles

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local verbose = RunService:IsStudio()
do
	local ok, DebugConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DebugConfig"))
	end)
	if ok and type(DebugConfig) == "table" and DebugConfig.Server and type(DebugConfig.Server.BikeMonitorVerbose) == "boolean" then
		verbose = DebugConfig.Server.BikeMonitorVerbose
	end
	local attr = ReplicatedStorage:GetAttribute("ServerBikeMonitorVerbose")
	if type(attr) == "boolean" then
		verbose = attr
	end
	ReplicatedStorage:GetAttributeChangedSignal("ServerBikeMonitorVerbose"):Connect(function()
		local v = ReplicatedStorage:GetAttribute("ServerBikeMonitorVerbose")
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

vprint("🔍 === Bike Monitor System Starting ===")

local Players = game:GetService("Players")

local function getEnabledStatus(instance)
	if instance:IsA("LocalScript") or instance:IsA("Script") then
		return tostring(instance.Enabled)
	end
	return "N/A"
end

-- Monitor all descendants added to workspace (when bike spawns)
workspace.DescendantAdded:Connect(function(descendant)
	-- Check if it's part of a bike
	local parent = descendant.Parent
	if parent and (parent.Name:find("Honda") or parent.Name:find("CBR") or parent.Name:find("Fireblade")) then
		local bikeModel = descendant:FindFirstAncestorOfClass("Model")
		if bikeModel then
			vprint(string.format("📦 [BIKE PART ADDED] %s.%s (Type: %s)", bikeModel.Name, descendant:GetFullName():gsub("Workspace%.", ""), descendant.ClassName))
			
			-- Log scripts specifically
			if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
				vprint(string.format("   📜 [SCRIPT DETECTED] %s | Enabled: %s | Path: %s", 
					descendant.Name, 
					getEnabledStatus(descendant), 
					descendant:GetFullName()))
			end
		end
	end
end)

-- Monitor PlayerGui for bike-related GUI scripts
Players.PlayerAdded:Connect(function(player)
	player:WaitForChild("PlayerGui")
	
	player.PlayerGui.DescendantAdded:Connect(function(descendant)
		-- Check if it's bike-related GUI
		if descendant.Parent and (descendant.Parent.Name == "Interface" or descendant.Parent.Name:find("Bike") or descendant.Parent.Name:find("Motor")) then
			vprint(string.format("🖥️ [GUI DETECTED] Player: %s | Element: %s (Type: %s) | Path: %s", 
				player.Name, 
				descendant.Name, 
				descendant.ClassName,
				descendant:GetFullName():gsub("Players%." .. player.Name .. "%.PlayerGui%.", "")))
			
			-- Log GUI scripts
			if descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
				vprint(string.format("   📜 [GUI SCRIPT] %s | Enabled: %s", descendant.Name, getEnabledStatus(descendant)))
			end
		end
	end)
end)

-- Monitor existing bikes in workspace
task.spawn(function()
	task.wait(2) -- Wait for initial load
	
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and (model.Name:find("Honda") or model.Name:find("CBR") or model.Name:find("Fireblade")) then
			vprint(string.format("🏍️ [EXISTING BIKE FOUND] %s", model.Name))
			vprint(string.format("   📊 [BIKE STRUCTURE] Listing all children:"))
			
			for _, child in ipairs(model:GetDescendants()) do
				if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
					vprint(string.format("      📜 Script: %s | Type: %s | Enabled: %s | Path: %s", 
						child.Name, 
						child.ClassName,
						getEnabledStatus(child),
						child:GetFullName():gsub("Workspace%.", "")))
				elseif child:IsA("ScreenGui") or child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
					vprint(string.format("      🖥️ GUI: %s | Type: %s | Path: %s", 
						child.Name, 
						child.ClassName,
						child:GetFullName():gsub("Workspace%.", "")))
				end
			end
		end
	end
end)

vprint("✓ Bike Monitor System Active")
