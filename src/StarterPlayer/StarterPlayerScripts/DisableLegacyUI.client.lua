-- This script's sole purpose is to find and disable the legacy "Interface" GUI
-- to prevent it from conflicting with the new MotorcycleHUD. It leaves the "Values"
-- folder intact so the new HUD can continue reading RPM and other data.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function findAndSuppressLegacyGui()
    local interfaceGui = playerGui:FindFirstChild("Interface")
    if not interfaceGui then
        return false
    end

    -- Recursively go through all descendants of the legacy GUI
    for _, descendant in ipairs(interfaceGui:GetDescendants()) do
        -- Leave the "Values" folder and its children alone
        if descendant.Name ~= "Values" and not descendant:IsDescendantOf(interfaceGui:FindFirstChild("Values", true)) then
            -- Disable scripts
            if descendant:IsA("BaseScript") then
                pcall(function()
                    descendant.Disabled = true
                end)
            -- Hide visible objects
            elseif descendant:IsA("GuiObject") then
                pcall(function()
                    descendant.Visible = false
                end)
            end
        end
    end
    
    -- Also disable the ScreenGui itself to be sure
    interfaceGui.Enabled = false

    print("✓ Legacy 'Interface' GUI has been suppressed.")
    return true
end

-- The legacy GUI might be added at any point.
-- We need to watch for it.
playerGui.ChildAdded:Connect(function(child)
    if child.Name == "Interface" then
        findAndSuppressLegacyGui()
    end
end)

-- Also run it once at the start in case it's already there
findAndSuppressLegacyGui()
