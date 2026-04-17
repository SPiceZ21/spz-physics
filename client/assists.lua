-- client/assists.lua

local lcActive = false

local function UpdateTCS(vehicle, profile, throttle)
  if not PhysicsState or not PhysicsState.tcs_enabled then return false end
  local tcsActive = false

  -- Detect driven wheel spin by comparing wheel speeds
  -- 0/1 are front, 2/3 are rear. 
  local frontSpeed = (GetVehicleWheelSpeed(vehicle, 0) + GetVehicleWheelSpeed(vehicle, 1)) / 2
  local rearSpeed  = (GetVehicleWheelSpeed(vehicle, 2) + GetVehicleWheelSpeed(vehicle, 3)) / 2
  
  local slipMagnitude = 0
  if profile.drivetrain == "RWD" then
      slipMagnitude = math.max(0, rearSpeed - frontSpeed)
  elseif profile.drivetrain == "FWD" then
      slipMagnitude = math.max(0, frontSpeed - rearSpeed)
  else -- AWD
      -- Simplified AWD slip: target is the overall vehicle speed
      local vehSpeed = GetEntitySpeed(vehicle)
      slipMagnitude = math.max(0, rearSpeed - vehSpeed, frontSpeed - vehSpeed)
  end

  local multiplier = 1.0
  if slipMagnitude > threshold and throttle > 0.3 then
    -- Cut torque proportionally to slip magnitude
    local cut = math.min(0.95, (slipMagnitude / threshold) * 0.2)
    multiplier = 1.0 - cut
    tcsActive = true
  end

  return tcsActive, multiplier
end

local function UpdateABS(vehicle, profile, brake)
  if not PhysicsState or not PhysicsState.abs_enabled then return false end
  local absActive = false
  
  if brake > 0.5 then
      -- Detect wheel lock
      local speed = GetEntitySpeed(vehicle)
      if speed > 2.0 then
          local locked = false
          for i = 0, 3 do
              if GetVehicleWheelSpeed(vehicle, i) < (speed * 0.1) then
                  locked = true
                  break
              end
          end
          
          if locked then
              -- Release brakes slightly to regain traction
              SetVehicleForwardSpeed(vehicle, speed + 0.1) -- Dirty hack to "pulse" brakes in GTA
              absActive = true
          end
      end
  end
  
  return absActive
end

local function UpdateLC(vehicle, profile, speed, throttle, brake)
  if not PhysicsState or not PhysicsState.lc_enabled then return false end

  local targetRpm = profile.engine.lc_rpm or Config.LCTargetRPM or 4000
  
  -- Activate LC: player holds brake + throttle while stationary
  if brake > 0.9 and throttle > 0.9 and speed < 2.0 then
    lcActive = true
    -- Hold RPM at target by modulating torque/multiplier
    -- We'll handle the actual RPM capping in the tick loop
    TriggerEvent("SPZ:physics:lcActive", true)
  elseif lcActive and brake < 0.1 then
    -- Release — full power
    lcActive = false
    TriggerEvent("SPZ:physics:lcActive", false)
  end

  return lcActive
end

SPZAssists = {
    UpdateTCS = UpdateTCS,
    UpdateABS = UpdateABS,
    UpdateLC = UpdateLC
}
