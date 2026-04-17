-- client/engine.lua

local function GetPowerAtRPM(rpm, curve)
  local keys = {}
  for k in pairs(curve) do table.insert(keys, k) end
  table.sort(keys)

  for i = 1, #keys - 1 do
    local r0, r1 = keys[i], keys[i+1]
    if rpm >= r0 and rpm <= r1 then
      local t = (rpm - r0) / (r1 - r0)
      return curve[r0] + t * (curve[r1] - curve[r0])
    end
  end
  return 0.0
end

local function CalculateRPM(vehicle, profile)
  local nativeRpm = GetVehicleCurrentRpm(vehicle)   -- 0.0–1.0
  local rpm = profile.engine.rpm_min +
    (nativeRpm * (profile.engine.rpm_max - profile.engine.rpm_min))

  -- Rev limiter — bounce if over rpm_limit
  if rpm >= profile.engine.rpm_limit then
    SetVehicleCurrentRpm(vehicle,
      profile.engine.rpm_max / profile.engine.rpm_limit)
    TriggerEvent("SPZ:physics:revLimiter")
  end

  return math.floor(rpm)
end

SPZEngine = {
    CalculateRPM = CalculateRPM,
    GetPowerAtRPM = GetPowerAtRPM
}
