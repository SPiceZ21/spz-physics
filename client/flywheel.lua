-- client/flywheel.lua
-- inertia 0.0 = instant response, 1.0 = very heavy flywheel
-- Applied as a smoothing factor on the RPM tick
local smoothedRpm = 0

local function UpdateRpm(targetRpm, inertia)
  smoothedRpm = smoothedRpm + (targetRpm - smoothedRpm) * (1.0 - inertia)
  return math.floor(smoothedRpm)
end

SPZFlywheel = {
    UpdateRpm = UpdateRpm
}
