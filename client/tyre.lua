-- client/tyre.lua

local function GetGripAtSlip(slipAngleDeg, compound)
  if not compound or not compound.lat_curve then return 1.0 end
  
  local curve = compound.lat_curve
  local keys = {}
  for k in pairs(curve) do table.insert(keys, k) end
  table.sort(keys)

  for i = 1, #keys - 1 do
    local a0, a1 = keys[i], keys[i+1]
    if slipAngleDeg >= a0 and slipAngleDeg <= a1 then
      local t = (slipAngleDeg - a0) / (a1 - a0)
      local grip = curve[a0] + t * (curve[a1] - curve[a0])
      return compound.min_g + grip * (compound.max_g - compound.min_g)
    end
  end
  return compound.min_g
end

local function ApplyTyrePhysics(vehicle, profile, currentSpeed)
    local tyreCompound = TireData[profile.tyre] or TireData["street"]
    
    -- Basic slip angle calculation (simplified)
    -- slipAngle = steeringInput - atan2(velocityY, velocityX)
    local velocity = GetEntityVelocity(vehicle)
    local speed = GetEntitySpeed(vehicle)
    local steering = GetVehicleSteeringAngle(vehicle) -- Degrees
    
    local lateralVelocity = GetEntitySpeedVector(vehicle, true).x
    local slipAngle = 0
    if speed > 1.0 then
        slipAngle = math.abs(steering - math.deg(math.asin(lateralVelocity / speed)))
    end

    local grip = GetGripAtSlip(slipAngle, tyreCompound)
    
    -- Apply grip to handling floats
    -- Native GTA handling values: fTractionCurveMax, fTractionCurveMin
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", grip)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin", grip * 0.8)
    
    return grip
end

SPZTyre = {
    GetGripAtSlip = GetGripAtSlip,
    ApplyTyrePhysics = ApplyTyrePhysics
}
