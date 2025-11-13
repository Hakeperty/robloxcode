-- ClientLogger.lua
-- Lightweight client-side logging with channels and rate-limited print, plus rolling buffer

local ClientLogger = {}

local HttpService = game:GetService("HttpService")

-- Channels you can toggle on/off
ClientLogger._channels = {
	Camera = true,
	Input = true,
	GUI = true,
	HUD = true,
	Burnout = true,
	Weather = true,
}

ClientLogger._enabled = true
ClientLogger._buffer = {}
ClientLogger._bufferMax = 500
ClientLogger._lastPrintAt = 0
ClientLogger._minPrintInterval = 0 -- set >0 to globally throttle printing

local function nowStr()
	return string.format("%.3f", os.clock())
end

local function pushBuffer(entry)
	table.insert(ClientLogger._buffer, entry)
	if #ClientLogger._buffer > ClientLogger._bufferMax then
		table.remove(ClientLogger._buffer, 1)
	end
end

function ClientLogger.SetEnabled(enabled)
	ClientLogger._enabled = not not enabled
end

function ClientLogger.SetChannelEnabled(channel, enabled)
	ClientLogger._channels[channel] = not not enabled
end

function ClientLogger.GetBuffer()
	return ClientLogger._buffer
end

local function doPrint(text)
	local t = os.clock()
	if ClientLogger._minPrintInterval > 0 then
		if (t - (ClientLogger._lastPrintAt or 0)) < ClientLogger._minPrintInterval then
			return
		end
		ClientLogger._lastPrintAt = t
	end
	print(text)
end

function ClientLogger.Log(channel, msg, data)
	if not ClientLogger._enabled then return end
	if channel and ClientLogger._channels[channel] == false then return end
	local payload
	if data ~= nil then
		local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
		payload = ok and json or tostring(data)
	end
	local line
	if payload then
		line = string.format("[%s][%s] %s | %s", nowStr(), tostring(channel or ""), tostring(msg), payload)
	else
		line = string.format("[%s][%s] %s", nowStr(), tostring(channel or ""), tostring(msg))
	end
	pushBuffer({ at = os.clock(), channel = channel, msg = msg, data = data })
	doPrint(line)
end

function ClientLogger.Info(channel, msg, data)
	ClientLogger.Log(channel, msg, data)
end

function ClientLogger.Warn(channel, msg, data)
	ClientLogger.Log(channel or "WARN", msg, data)
end

function ClientLogger.Error(channel, msg, data)
	ClientLogger.Log(channel or "ERROR", msg, data)
end

return ClientLogger
