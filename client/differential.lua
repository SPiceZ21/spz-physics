-- client/differential.lua
local function ApplyAWDSplit(vehicle, profile, throttleInput)
  if profile.drivetrain ~= "AWD" then return end
  local front = profile.differential.awd_front_bias / 100
  local rear  = 1.0 - front
  -- Applied as handling float adjustments
  SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront", front)
end

SPZDifferential = {
    ApplyAWDSplit = ApplyAWDSplit
}
