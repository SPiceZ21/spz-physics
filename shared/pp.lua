-- client/pp.lua
local function CalculatePP(profile, isTuned, turboOverride)
  local engine   = profile.engine
  local gearbox  = profile.gearbox
  local tyreMaxG = 1.10 -- Default fallback (Street) since TireData was removed
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
  -- Estimate top speed in km/h based on RPM, gears, and tyres
  local tyreRadius = 0.35
  local finalDrive = gearbox.final_drive
  local highestGearRatio = gearbox.ratios[gearbox.gears] or 1.0
  local rpmMax = engine.rpm_max
  local topSpeed = (rpmMax / (finalDrive * highestGearRatio)) * (2 * math.pi * tyreRadius) / 60 * 3.6
  local speedRating = math.min(100, topSpeed / 3.5)

  -- Acceleration rating (0–100) — power-to-weight
  local ptw = power_hp / weight
  local accRating = math.min(100, ptw * 35)

  -- Handling/Grip rating (0–100)
  local gripRating = math.min(100, tyreMaxG * 50)

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
