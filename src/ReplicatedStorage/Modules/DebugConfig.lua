-- DebugConfig.lua
-- Centralized debug/verbosity flags for client/server diagnostics

local DebugConfig = {}

-- Client-side GUI-related debug flags
DebugConfig.BikeGUI = {
    -- When true, BikeGUIMonitor will print detailed logs about GUI/script additions and bike mounts.
    -- Default is false (quiet) to avoid log spam in production. You can override per session in Studio.
    MonitorVerbose = false,
}

-- Server-side debug flags
DebugConfig.Server = {
    -- When true, BikeMonitor.server.lua will log detailed bike/GUI events on the server.
    BikeMonitorVerbose = false,
}

return DebugConfig
