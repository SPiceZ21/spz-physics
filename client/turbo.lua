-- client/turbo.lua
local currentBoost = 0.0

local function UpdateBoost(vehicle, profile, currentRpm, throttle)
  if profile.turbo.type == "none" then
    currentBoost = 0.0
    return
  end

  local t = profile.turbo
  local lag = t.lag_factor

  if throttle > 0.1 and currentRpm > t.boost_start_rpm then
    -- Build boost
    local rpmFactor = math.min(1.0,
      (currentRpm - t.boost_start_rpm) / (t.boost_peak_rpm - t.boost_start_rpm))
    local targetBoost = rpmFactor * t.max_boost_bar
    -- Lag smoothing — boost builds gradually
    currentBoost = currentBoost + (targetBoost - currentBoost) * (1.0 - lag) * 0.016
  else
    -- Decay boost on throttle lift
    currentBoost = currentBoost * (1.0 - t.boost_decay)
  end

  currentBoost = math.max(0.0, math.min(currentBoost, t.max_boost_bar))

  -- Apply boost as engine torque multiplier bonus
  local boostMultiplier = 1.0 + (currentBoost / t.max_boost_bar) * 0.35
  SetVehicleEngineTorqueMultiplier(vehicle, boostMultiplier)
end

SPZTurbo = {
    UpdateBoost = UpdateBoost
}
