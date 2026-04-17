-- client/pp.lua
local function CalculatePP(profile, isTuned, turboOverride)
  local engine   = profile.engine
  local gearbox  = profile.gearbox
  local tyre     = TireData[profile.tyre]
  local weight   = profile.weight

  -- Power rating (0–100)
  local power_hp = engine.power_hp
  if isTuned and turboOverride then
    -- Add boost power bonus
    local boostBonus = turboOverride.max_boost_bar * 45
    power_hp = power_hp + boostBonus
  end
  local powerRating = math.min(100, power_hp / 6.0)

  -- Speed rating (0–100)
  -- Use SPZGearbox to estimate top speed, supplying a default tyre radius of 0.35 if unknown
  local topSpeed = SPZGearbox and SPZGearbox.EstimateTopSpeed(profile, 0.35) or 250
  local speedRating = math.min(100, topSpeed / 3.5)

  -- Acceleration rating (0–100) — power-to-weight
  local ptw = power_hp / weight
  local accRating = math.min(100, ptw * 35)

  -- Handling/Grip rating (0–100)
  local gripRating = math.min(100, tyre.max_g * 50)

  -- PP = weighted sum
  local pp = (powerRating * 0.30) +
             (speedRating * 0.25) +
             (accRating   * 0.25) +
             (gripRating  * 0.20)

  return {
    pp       = math.floor(pp * 10) / 10,
    power    = math.floor(powerRating),
    speed    = math.floor(speedRating),
    acc      = math.floor(accRating),
    grip     = math.floor(gripRating),
    power_hp = math.floor(power_hp),
    top_speed= math.floor(topSpeed),
  }
end

SPZPP = {
    CalculatePP = CalculatePP
}
