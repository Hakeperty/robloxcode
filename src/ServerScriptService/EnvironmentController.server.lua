-- EnvironmentController.server.lua
-- Drives day/night cycle and lightweight dynamic weather via ReplicatedStorage attributes

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ensure attributes exist with sane defaults
if ReplicatedStorage:GetAttribute("RainIntensity") == nil then
    ReplicatedStorage:SetAttribute("RainIntensity", 0.0)
end
if ReplicatedStorage:GetAttribute("WindDirection") == nil then
    ReplicatedStorage:SetAttribute("WindDirection", Vector3.new(0, 0, 0))
end
if ReplicatedStorage:GetAttribute("WindSpeed") == nil then
    ReplicatedStorage:SetAttribute("WindSpeed", 0)
end
if ReplicatedStorage:GetAttribute("SunGlareIntensity") == nil then
    ReplicatedStorage:SetAttribute("SunGlareIntensity", 0)
end
if ReplicatedStorage:GetAttribute("WindGust") == nil then
    ReplicatedStorage:SetAttribute("WindGust", 0)
end
if ReplicatedStorage:GetAttribute("Wetness") == nil then
    ReplicatedStorage:SetAttribute("Wetness", 0)
end
if ReplicatedStorage:GetAttribute("StormFlash") == nil then
    ReplicatedStorage:SetAttribute("StormFlash", 0)
end
if ReplicatedStorage:GetAttribute("WeatherDebugOverride") == nil then
    ReplicatedStorage:SetAttribute("WeatherDebugOverride", false)
end
-- Optional forced time when debug override is on
if ReplicatedStorage:GetAttribute("ForcedClockTime") == nil then
    ReplicatedStorage:SetAttribute("ForcedClockTime", -1)
end

-- Day/night config
local dayLengthSeconds = 8 * 60 -- 8 min per full day by default
local startTime = os.clock()

-- Weather state
local weather = {
    targetRain = 0.0,
    currentRain = ReplicatedStorage:GetAttribute("RainIntensity") or 0,
    windDir = Vector3.new(0, 0, 0),
    windSpeed = 0,
    nextChangeAt = 0,
    gustPhase = math.random() * math.pi * 2,
}

local function randomUnitXZ()
    local angle = math.random() * math.pi * 2
    return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

local function pickNextWeather(now)
    -- 60% clear/overcast, 30% light rain, 10% heavy storm
    local r = math.random()
    if r < 0.6 then
        weather.targetRain = 0
        weather.windDir = randomUnitXZ()
        weather.windSpeed = math.random(0, 10)
        weather.nextChangeAt = now + math.random(60, 120)
    elseif r < 0.9 then
        weather.targetRain = math.random(20, 60) / 100 -- 0.2..0.6
        weather.windDir = randomUnitXZ()
        weather.windSpeed = math.random(6, 16)
        weather.nextChangeAt = now + math.random(45, 90)
    else
        weather.targetRain = math.random(70, 100) / 100 -- 0.7..1.0
        weather.windDir = randomUnitXZ()
        weather.windSpeed = math.random(12, 24)
        weather.nextChangeAt = now + math.random(30, 60)
    end
end

-- Kick off first weather selection
pickNextWeather(os.clock())

task.spawn(function()
    while true do
        local now = os.clock()
        local debugOverride = ReplicatedStorage:GetAttribute("WeatherDebugOverride") == true

        if not debugOverride then
            -- Advance time of day automatically
            local dayT = (now - startTime) / dayLengthSeconds -- 0..1
            local clockTime = (dayT * 24) % 24
            
            -- Validate clock time before setting
            if typeof(clockTime) == "number" and not (clockTime ~= clockTime) then -- Check for NaN
                Lighting.ClockTime = clockTime
            end

            -- Expose glare based on sun height
            local sunDir = Lighting:GetSunDirection()
            if sunDir and typeof(sunDir) == "Vector3" then
                local sunUp = math.max(0, sunDir.Y)
                local glare = sunUp -- 0 at night, 1 at noon
                ReplicatedStorage:SetAttribute("SunGlareIntensity", glare)
            end

            -- Weather state machine
            if now >= (weather.nextChangeAt or 0) then
                pickNextWeather(now)
            end
            -- Smoothly approach target rain
            local cur = weather.currentRain or 0
            local target = weather.targetRain or 0
            local delta = (target - cur)
            -- slightly smoother rain transitions
            cur = cur + math.clamp(delta, -0.007, 0.007)
            weather.currentRain = math.clamp(cur, 0, 1)

            -- wind gusts: slow sine + noise
            weather.gustPhase = weather.gustPhase + 0.03
            local base = 0.5 + 0.5 * math.sin(weather.gustPhase)
            local gust = math.clamp(base + (math.random() - 0.5) * 0.2, 0, 1)
            ReplicatedStorage:SetAttribute("WindGust", gust)

            -- Publish attributes for clients
            ReplicatedStorage:SetAttribute("RainIntensity", weather.currentRain)
            ReplicatedStorage:SetAttribute("WindDirection", weather.windDir)
            ReplicatedStorage:SetAttribute("WindSpeed", weather.windSpeed)

            -- Wetness accumulation (0..1): increases with rain, decays slowly without
            local wet = ReplicatedStorage:GetAttribute("Wetness") or 0
            if weather.currentRain > 0.05 then
                wet = math.clamp(wet + weather.currentRain * 0.01, 0, 1)
            else
                wet = math.max(0, wet - 0.002)
            end
            ReplicatedStorage:SetAttribute("Wetness", wet)

            -- Occasional storm flash during heavy rain
            if weather.currentRain >= 0.85 and math.random() < 0.01 then
                ReplicatedStorage:SetAttribute("StormFlash", 1)
                task.delay(0.2, function()
                    ReplicatedStorage:SetAttribute("StormFlash", 0)
                end)
            end
        else
            -- When overridden, keep Lighting.ClockTime fixed if ForcedClockTime >= 0
            local forced = ReplicatedStorage:GetAttribute("ForcedClockTime")
            if typeof(forced) == "number" and forced >= 0 then
                Lighting.ClockTime = forced % 24
            end
            -- Attributes are driven by clients; do nothing here.
        end

        task.wait(0.05)
    end
end)
