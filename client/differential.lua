-- client/differential.lua

local function ApplyAWDSplit(vehicle, profile)
  if profile.drivetrain ~= "AWD" or not profile.differential or not profile.differential.awd_front_bias then return end
  local front = profile.differential.awd_front_bias / 100
  -- Applied as handling float adjustments
  SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront", front)
end

local function UpdateDifferential(vehicle, profile)
    if profile.drivetrain == "AWD" then
        ApplyAWDSplit(vehicle, profile)
    end
    
    -- LSD Logic would go here (modulating individual wheel speeds/torque)
    -- For now we use handling floats to simulate LSD behavior
    if profile.differential and profile.differential.type == "LSD" then
        local lock = profile.differential.lock_pct / 100
        -- Lower values here in GTA handling mean more LSD lock/torque transfer
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionBiasFront", 0.5 + (lock * 0.1)) 
    end
end

SPZDifferential = {
    UpdateDifferential = UpdateDifferential
}
