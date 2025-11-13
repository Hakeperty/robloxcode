-- WeatherDebug.client.lua
-- Minimal testing UI to control rain, wind, and time of day. Server respects override.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientLogger"))
	end)
	if ok then Logger = mod end
end
local player = Players.LocalPlayer

local function ensureGui()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return nil end
	local existing = gui:FindFirstChild("WeatherDebug")
	if existing then return existing end
	local sg = Instance.new("ScreenGui")
	sg.Name = "WeatherDebug"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = gui
	return sg
end

local function makeButton(parent, name, text, posY, onClick)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.new(0, 160, 0, 28)
	b.Position = UDim2.new(0, 16, 0, posY)
	b.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
	b.BackgroundTransparency = 0.1
	b.TextColor3 = Color3.fromRGB(230, 240, 255)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	b.MouseButton1Click:Connect(function()
		onClick()
	end)
	return b
end

local function formatVal(x)
	if typeof(x) == "number" then
		return string.format("%.2f", x)
	elseif typeof(x) == "Vector3" then
		return string.format("(%.2f, %.2f, %.2f)", x.X, x.Y, x.Z)
	end
	return tostring(x)
end

local root = ensureGui()
if not root then return end

-- Panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 192, 0, 210)
panel.Position = UDim2.new(0, 24, 0, 120)
panel.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = root

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -8, 0, 20)
title.Position = UDim2.new(0, 8, 0, 6)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(200, 210, 225)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Weather Debug"
title.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -8, 0, 18)
status.Position = UDim2.new(0, 8, 0, 28)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(160, 170, 190)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Override: off"
status.Parent = panel

local posY = 52

makeButton(panel, "ToggleOverride", "Toggle Override", posY, function()
	local val = ReplicatedStorage:GetAttribute("WeatherDebugOverride")
	ReplicatedStorage:SetAttribute("WeatherDebugOverride", not val)
	status.Text = "Override: " .. tostring(not not ReplicatedStorage:GetAttribute("WeatherDebugOverride"))
	if Logger then Logger.Info("Weather", "ToggleOverride", { enabled = ReplicatedStorage:GetAttribute("WeatherDebugOverride") == true }) end
end)
posY = posY + 32

makeButton(panel, "RainMinus", "Rain -", posY, function()
	local r = tonumber(ReplicatedStorage:GetAttribute("RainIntensity")) or 0
	r = math.clamp(r - 0.1, 0, 1)
	ReplicatedStorage:SetAttribute("RainIntensity", r)
	if Logger then Logger.Info("Weather", "Rain", { value = r }) end
end)

makeButton(panel, "RainPlus", "Rain +", posY, function()
	local r = tonumber(ReplicatedStorage:GetAttribute("RainIntensity")) or 0
	r = math.clamp(r + 0.1, 0, 1)
	ReplicatedStorage:SetAttribute("RainIntensity", r)
	if Logger then Logger.Info("Weather", "Rain", { value = r }) end
end)
posY = posY + 32

makeButton(panel, "WindLeft", "Wind ◄", posY, function()
	local dir = Vector3.new(-1,0,0)
	ReplicatedStorage:SetAttribute("WindDirection", dir)
	if Logger then Logger.Info("Weather", "WindDir", { x = dir.X, y = dir.Y, z = dir.Z }) end
end)

makeButton(panel, "WindRight", "Wind ►", posY, function()
	local dir = Vector3.new(1,0,0)
	ReplicatedStorage:SetAttribute("WindDirection", dir)
	if Logger then Logger.Info("Weather", "WindDir", { x = dir.X, y = dir.Y, z = dir.Z }) end
end)
posY = posY + 32

makeButton(panel, "WindSpd-", "Wind -", posY, function()
	local s = tonumber(ReplicatedStorage:GetAttribute("WindSpeed")) or 0
	s = math.max(0, s - 2)
	ReplicatedStorage:SetAttribute("WindSpeed", s)
	if Logger then Logger.Info("Weather", "WindSpeed", { value = s }) end
end)

makeButton(panel, "WindSpd+", "Wind +", posY, function()
	local s = tonumber(ReplicatedStorage:GetAttribute("WindSpeed")) or 0
	s = math.min(40, s + 2)
	ReplicatedStorage:SetAttribute("WindSpeed", s)
	if Logger then Logger.Info("Weather", "WindSpeed", { value = s }) end
end)
posY = posY + 32

makeButton(panel, "TimeNight", "Time: Night", posY, function()
	ReplicatedStorage:SetAttribute("ForcedClockTime", 22)
	if Logger then Logger.Info("Weather", "ForcedClockTime", { value = 22 }) end
end)

makeButton(panel, "TimeNoon", "Time: Noon", posY, function()
	ReplicatedStorage:SetAttribute("ForcedClockTime", 12)
	if Logger then Logger.Info("Weather", "ForcedClockTime", { value = 12 }) end
end)

makeButton(panel, "TimeAuto", "Time: Auto", posY, function()
	ReplicatedStorage:SetAttribute("ForcedClockTime", -1)
	if Logger then Logger.Info("Weather", "ForcedClockTime", { value = -1 }) end
end)
