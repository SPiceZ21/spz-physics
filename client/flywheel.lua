-- client/flywheel.lua

-- inertia 0.0 = instant response, 1.0 = very heavy flywheel
-- Applied as a smoothing factor on the RPM tick
local smoothedRpm = 0

local function UpdateRpm(targetRpm, inertia)
  if smoothedRpm == 0 then smoothedRpm = targetRpm end
  smoothedRpm = smoothedRpm + (targetRpm - smoothedRpm) * (1.0 - (inertia or 0.35))
  return math.floor(smoothedRpm)
end

local function ResetFlywheel(rpm)
    smoothedRpm = rpm
end

SPZFlywheel = {
    UpdateRpm = UpdateRpm,
    ResetFlywheel = ResetFlywheel
}
