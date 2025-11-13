-- SeatLogger.lua
-- Logs when players sit on or leave seats

local Players = game:GetService("Players")

local SeatLogger = {}

-- Monitor all seats in workspace
function SeatLogger:Initialize()
	print("=== Seat Logger Initialized ===")
	
	-- Monitor existing seats
	for _, descendant in pairs(workspace:GetDescendants()) do
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			self:MonitorSeat(descendant)
		end
	end
	
	-- Monitor new seats added to workspace
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
			self:MonitorSeat(descendant)
		end
	end)
	
	print("✓ Monitoring all seats in workspace")
end

-- Monitor a specific seat
function SeatLogger:MonitorSeat(seat)
	-- Log when occupant changes
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		
		if occupant then
			-- Someone sat down
			local player = Players:GetPlayerFromCharacter(occupant.Parent)
			if player then
				local seatPath = self:GetSeatPath(seat)
				print("🪑 [SEAT] " .. player.Name .. " SAT on: " .. seatPath)
				print("   └─ Seat Type: " .. seat.ClassName)
				print("   └─ Seat Name: " .. seat.Name)
				
				if seat:IsA("VehicleSeat") then
					local vehicle = self:FindVehicleModel(seat)
					if vehicle then
						print("   └─ Vehicle: " .. vehicle.Name)
					end
				end
			end
		else
			-- Someone stood up (but we don't know who from this event)
			local seatPath = self:GetSeatPath(seat)
			print("🪑 [SEAT] Someone LEFT: " .. seatPath)
		end
	end)
end

-- Get the full path to a seat
function SeatLogger:GetSeatPath(seat)
	local path = seat.Name
	local parent = seat.Parent
	
	while parent and parent ~= workspace do
		path = parent.Name .. "." .. path
		parent = parent.Parent
	end
	
	return path
end

-- Find the vehicle model that contains this seat
function SeatLogger:FindVehicleModel(seat)
	local parent = seat.Parent
	
	while parent and parent ~= workspace do
		if parent:IsA("Model") then
			-- Check if this model has multiple parts (likely a vehicle)
			local parts = parent:GetChildren()
			local partCount = 0
			for _, child in pairs(parts) do
				if child:IsA("BasePart") then
					partCount = partCount + 1
				end
			end
			
			if partCount > 3 then
				return parent
			end
		end
		parent = parent.Parent
	end
	
	return nil
end

-- Start the logger
SeatLogger:Initialize()

return SeatLogger
