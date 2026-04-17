-- client/gearbox.lua

local shiftLocked = false

local function TryShiftUp(vehicle, profile)
  local gear = GetVehicleCurrentGear(vehicle)
  if gear >= profile.gearbox.gears then return end
  if shiftLocked then return end

  shiftLocked = true
  -- Apply shift delay — brief torque cut during shift
  SetVehicleEngineTorqueMultiplier(vehicle, 0.0)
  Wait(profile.gearbox.shift_delay)
  SetVehicleCurrentGear(vehicle, gear + 1)
  shiftLocked = false
end

local function TryShiftDown(vehicle, profile)
  local gear = GetVehicleCurrentGear(vehicle)
  if gear <= 1 then return end
  if shiftLocked then return end

  -- Blip throttle on downshift (heel-toe)
  shiftLocked = true
  SetVehicleEngineTorqueMultiplier(vehicle, 0.3)
  Wait(profile.gearbox.shift_delay)
  SetVehicleCurrentGear(vehicle, gear - 1)
  shiftLocked = false
end

local function AutoShift(vehicle, profile, currentRpm)
  local gear = GetVehicleCurrentGear(vehicle)
  local shiftRpm = profile.engine.rpm_max * profile.gearbox.at_shift_point

  if currentRpm >= shiftRpm and gear < profile.gearbox.gears then
    TryShiftUp(vehicle, profile)
  elseif currentRpm < profile.engine.rpm_min * 1.2 and gear > 1 then
    TryShiftDown(vehicle, profile)
  end
end

-- Calculate real engine RPM from wheel speed, gear ratio, and tyre radius
local function CalculateRPMFromWheelSpeed(vehicleSpeedMs, gearRatio, finalDrive, tyreRadius)
  if tyreRadius == 0 then return 0 end
  -- engine_rpm = wheel_speed * gear_ratio * final_drive * 60 / (2 * pi * tyre_radius)
  return (vehicleSpeedMs * gearRatio * finalDrive * 60) / (2 * math.pi * tyreRadius)
end

-- Estimate top speed in km/h based on RPM, gears, and tyres
local function EstimateTopSpeed(profile, tyreRadius)
  if tyreRadius == 0 then return 0 end
  local finalDrive = profile.gearbox.final_drive
  local highestGearRatio = profile.gearbox.ratios[profile.gearbox.gears] or 1.0
  local rpmMax = profile.engine.rpm_max
  
  -- top_speed_kmh = (rpm_max / (final_drive * highest_gear_ratio)) * (2 * pi * tyre_radius) / 60 * 3.6
  return (rpmMax / (finalDrive * highestGearRatio)) * (2 * math.pi * tyreRadius) / 60 * 3.6
end

SPZGearbox = {
    TryShiftUp = TryShiftUp,
    TryShiftDown = TryShiftDown,
    AutoShift = AutoShift,
    CalculateRPMFromWheelSpeed = CalculateRPMFromWheelSpeed,
    EstimateTopSpeed = EstimateTopSpeed
}
