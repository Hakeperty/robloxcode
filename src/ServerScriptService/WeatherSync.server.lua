-- WeatherSync.server.lua
-- Optional scaffold to synchronize in-game weather with real-world data.
-- Disabled by default. Enable by setting ReplicatedStorage attribute "RealWeatherEnabled" to true
-- and implementing the HTTP provider inside the fetchRealWeather function.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure toggle attribute exists
if ReplicatedStorage:GetAttribute("RealWeatherEnabled") == nil then
	ReplicatedStorage:SetAttribute("RealWeatherEnabled", false)
end

-- Config: set your location and API key here if you opt in
local CONFIG = {
	provider = "OpenWeatherMap", -- just as an example
	apiKey = nil, -- set via Studio > ServerScriptService > WeatherSync or an external secret provider
	lat = nil, -- latitude
	lon = nil, -- longitude
	updateSeconds = 120,
}

local function mapToGameWeather(sample)
	-- sample: { rain=0..1, windSpeed=0..?, windDir=Vector3, wetness=0..1 }
	if typeof(sample) ~= "table" then return end
	ReplicatedStorage:SetAttribute("RainIntensity", math.clamp(tonumber(sample.rain) or 0, 0, 1))
	ReplicatedStorage:SetAttribute("WindSpeed", math.max(0, tonumber(sample.windSpeed) or 0))
	ReplicatedStorage:SetAttribute("WindDirection", sample.windDir or Vector3.new(0,0,0))
	ReplicatedStorage:SetAttribute("Wetness", math.clamp(tonumber(sample.wetness) or 0, 0, 1))
end

local function fetchRealWeather()
	-- SECURITY NOTE: Only implement if you consent to outbound HTTP from this experience.
	-- 1) In Studio: Home > Game Settings > Security > Allow HTTP Requests (enable)
	-- 2) Provide an API key and location above (CONFIG)
	-- 3) Implement provider call here. Example (OpenWeatherMap current weather):
	--    local url = string.format("https://api.openweathermap.org/data/2.5/weather?lat=%s&lon=%s&appid=%s&units=metric", CONFIG.lat, CONFIG.lon, CONFIG.apiKey)
	--    local ok, body = pcall(HttpService.GetAsync, HttpService, url)
	--    if ok then
	--       local obj = HttpService:JSONDecode(body)
	--       local rainMm = (obj.rain and (obj.rain["1h"] or obj.rain["3h"])) or 0
	--       local clouds = tonumber(obj.clouds and obj.clouds.all or 0) or 0
	--       local windSpeed = tonumber(obj.wind and obj.wind.speed or 0) or 0
	--       local windDeg = tonumber(obj.wind and obj.wind.deg or 0) or 0
	--       local dir = Vector3.new(math.cos(math.rad(windDeg)), 0, math.sin(math.rad(windDeg)))
	--       local rainNorm = math.clamp(rainMm / 5.0, 0, 1) -- normalize 0..5mm/hr to 0..1
	--       mapToGameWeather({ rain = rainNorm, windSpeed = windSpeed, windDir = dir, wetness = rainNorm })
	--    end
	-- For now, this function is a stub and returns nil.
	return nil
end

-- Background loop when enabled
spawn(function()
	local nextAt = 0
	while true do
		local enabled = ReplicatedStorage:GetAttribute("RealWeatherEnabled") == true
		local now = os.clock()
		if enabled and now >= nextAt then
			local sample = fetchRealWeather()
			if sample then
				mapToGameWeather(sample)
			end
			nextAt = now + (CONFIG.updateSeconds or 120)
		end
		wait(1)
	end
end)
