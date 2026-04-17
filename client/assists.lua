-- client/assists.lua

local lcActive = false
local tcActive = false
local LC_RPM_TARGET = Config and Config.LCTargetRPM or 4000

local function UpdateTCS(vehicle, profile, throttle)
  local assistsConfig = profile.assists or {}
  -- Assuming PhysicsState is defined globally in tick.lua
  local tcs_enabled = true
  if PhysicsState and PhysicsState.tcs_enabled ~= nil then tcs_enabled = PhysicsState.tcs_enabled end

  if not tcs_enabled or not assistsConfig.tcs then return end
  tcActive = false

  -- Detect rear wheel spin by comparing wheel speeds
  local rearSlip = GetVehicleWheelSpeed(vehicle, 2) - GetVehicleWheelSpeed(vehicle, 0)
  local slipThreshold = Config and Config.TCSSlipThreshold or 0.25

  if rearSlip > slipThreshold and throttle > 0.5 then
    -- Cut torque proportionally to slip magnitude
    local cut = math.min(0.95, rearSlip / slipThreshold * 0.3)
    SetVehicleEngineTorqueMultiplier(vehicle, 1.0 - cut)
    tcActive = true
  end

  LocalPlayer.state:set("physics:tcs_active", tcActive, true)
end

local function UpdateLC(vehicle, profile, speed, throttle, brake)
  local assistsConfig = profile.assists or {}
  if not assistsConfig.lc then return end

  -- Activate LC: player holds brake + throttle while stationary
  if brake > 0.9 and throttle > 0.9 and speed < 5 then
    lcActive = true
    -- Hold RPM at LC_RPM_TARGET by modulating throttle
    local currentRpm = PhysicsState and PhysicsState.rpm or 0
    if currentRpm > LC_RPM_TARGET then
      SetVehicleEngineTorqueMultiplier(vehicle, 0.1)
    else
      SetVehicleEngineTorqueMultiplier(vehicle, 1.0)
    end
  elseif lcActive and brake < 0.1 then
    -- Release — full power
    lcActive = false
  end

  LocalPlayer.state:set("physics:lc_active", lcActive, true)
end

SPZAssists = {
    UpdateTCS = UpdateTCS,
    UpdateLC = UpdateLC
}
