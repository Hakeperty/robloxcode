-- BurnoutFX.client.lua
-- Enables burnout smoke/sparks when the player is on a bike that supports Drive:GetState()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Logger do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientLogger"))
	end)
	if ok then Logger = mod end
end

local player = Players.LocalPlayer

local currentBike = nil
local burnoutHandle = nil
local inputConnBegin, inputConnEnd
local actionBound = false

local function teardown()
	currentBike = nil
	burnoutHandle = nil -- Burnout module manages enabling; no persistent emitters to clean here
	if inputConnBegin then inputConnBegin:Disconnect() inputConnBegin = nil end
	if inputConnEnd then inputConnEnd:Disconnect() inputConnEnd = nil end
	if actionBound then
		ContextActionService:UnbindAction("BurnoutHold")
		actionBound = false
	end
	if Logger then Logger.Info("Burnout", "Detached") end
end

local function tryAttachBurnout(bike)
	if not bike or not bike:IsA("Model") then return end
	currentBike = bike

	local ok, Burnout = pcall(function()
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		return require(Modules:WaitForChild("Burnout"))
	end)
	if not ok or type(Burnout) ~= "table" or type(Burnout.new) ~= "function" then
		warn("[BurnoutFX] Burnout module unavailable; skipping effects")
		return
	end

	-- Some bikes expose Scripts.Drive with GetState(). Burnout.new(bike) wires itself to Drive state.
	local success, res = pcall(function()
		return Burnout.new(bike)
	end)
	if success then
		burnoutHandle = res
		print("🔥 Burnout FX attached to ", bike:GetFullName())
		if Logger then Logger.Info("Burnout", "Attached", { bike = bike:GetFullName() }) end
		-- Bind Spacebar and sink it so jump doesn't fire while seated
		ContextActionService:BindAction(
			"BurnoutHold",
			function(actionName, state, input)
				if not burnoutHandle or not burnoutHandle.SetSpacePressed then
					return Enum.ContextActionResult.Pass
				end
				if state == Enum.UserInputState.Begin then
					burnoutHandle:SetSpacePressed(true)
					if Logger then Logger.Info("Input", "Space", { pressed = true }) end
					return Enum.ContextActionResult.Sink
				elseif state == Enum.UserInputState.End then
					burnoutHandle:SetSpacePressed(false)
					if Logger then Logger.Info("Input", "Space", { pressed = false }) end
					return Enum.ContextActionResult.Sink
				end
				return Enum.ContextActionResult.Pass
			end,
			false,
			Enum.KeyCode.Space
		)
		actionBound = true
	else
		warn("[BurnoutFX] Failed to attach:", res)
	end
end

local function onSeatChanged(humanoid)
	local seat = humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		local bike = seat.Parent
		if bike ~= currentBike then
			teardown()
			tryAttachBurnout(bike)
		end
	else
		teardown()
	end
end

local function trackCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10)
	end
	if not humanoid then return end

	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		onSeatChanged(humanoid)
	end)
	-- Fire once on join
	onSeatChanged(humanoid)
end

player.CharacterAdded:Connect(trackCharacter)
if player.Character then
	trackCharacter(player.Character)
end
