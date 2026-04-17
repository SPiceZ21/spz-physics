-- client/swaybar.lua

local function ApplySwaybars(vehicle, profile)
  if not profile.swaybar then return end
  
  local sb = profile.swaybar
  local totalStiffness = (sb.front_strength + sb.rear_strength) / 100.0
  local frontShare = sb.front_bias or 0.5

  -- fAntiRollBarForce: 0.0 to 1.0ish
  SetVehicleHandlingFloat(vehicle, "CHandlingData", "fAntiRollBarForce", totalStiffness * 0.8)
  
  -- fAntiRollBarBiasFront: 0.0 to 1.0 (0.5 is equal)
  SetVehicleHandlingFloat(vehicle, "CHandlingData", "fAntiRollBarBiasFront", frontShare)
end

SPZSwaybar = {
    ApplySwaybars = ApplySwaybars
}
