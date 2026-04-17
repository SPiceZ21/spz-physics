-- client/swaybar.lua
local function ApplySwaybars(vehicle, profile)
  local sb = profile.swaybar
  local totalStiffness = (sb.front_strength + sb.rear_strength) / 100.0
  local frontShare = sb.front_bias

  SetVehicleHandlingFloat(vehicle, "CHandlingData",
    "fAntiRollBarForce",       totalStiffness * 0.8)
  SetVehicleHandlingFloat(vehicle, "CHandlingData",
    "fAntiRollBarBiasFront",   frontShare)
end

SPZSwaybar = {
    ApplySwaybars = ApplySwaybars
}
