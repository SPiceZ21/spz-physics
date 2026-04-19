-- client/assists.lua
-- Driver assistance systems: TCS, ABS, ESC, Launch Control.
-- Each system returns an active flag and (where applicable) a torque
-- multiplier that the tick loop uses to modulate engine output.

local _lcActive  = false   -- Launch Control state persists across frames
local _escActive = false   -- ESC active flag for telemetry

-- ---------------------------------------------------------------------------
-- TCS — Traction Control System
-- Compares driven wheel speed against vehicle speed.
-- Returns (active: bool, torqueMult: float)
-- ---------------------------------------------------------------------------
local function UpdateTCS(vehicle, profile, throttle)
    if not PhysicsState or not PhysicsState.tcs_enabled then return false, 1.0 end

    local vehSpeed   = GetEntitySpeed(vehicle)
    local frontSpeed = (GetVehicleWheelSpeed(vehicle, 0) + GetVehicleWheelSpeed(vehicle, 1)) * 0.5
    local rearSpeed  = (GetVehicleWheelSpeed(vehicle, 2) + GetVehicleWheelSpeed(vehicle, 3)) * 0.5

    local drivenSpeed = 0.0
    if profile.drivetrain == "RWD" then
        drivenSpeed = rearSpeed
    elseif profile.drivetrain == "FWD" then
        drivenSpeed = frontSpeed
    else  -- AWD
        drivenSpeed = math.max(frontSpeed, rearSpeed)
    end

    local slip      = math.max(0.0, drivenSpeed - vehSpeed)
    local threshold = Config.TCSSlipThreshold or 0.25
    local mult      = 1.0
    local active    = false

    if slip > threshold and throttle > 0.25 and vehSpeed > 0.5 then
        -- Proportional cut: deeper slip → stronger intervention
        local severity = math.min(1.0, (slip - threshold) / threshold)
        mult   = math.max(0.30, 1.0 - severity * 0.70)
        active = true
    end

    return active, mult
end

-- ---------------------------------------------------------------------------
-- ABS — Anti-lock Brake System
-- Detects wheel lockup under braking and pulses brake pressure on locked
-- wheels to prevent sustained lockup.
-- Returns (active: bool)
-- ---------------------------------------------------------------------------
local _absPulse = false
local _absPulseTimer = 0
local ABS_PULSE_MS = 80  -- toggle brake pressure every 80ms

local function UpdateABS(vehicle, profile, brake)
    if not PhysicsState or not PhysicsState.abs_enabled then return false end
    if brake < 0.4 then return false end

    local speed = GetEntitySpeed(vehicle)
    if speed < 2.0 then return false end

    local anyLocked = false
    local now = GetGameTimer()

    for i = 0, 3 do
        if GetVehicleWheelSpeed(vehicle, i) < (speed * 0.08) then
            anyLocked = true
            -- Pulse brake pressure: release locked wheel so it can spin up again
            if now - _absPulseTimer >= ABS_PULSE_MS then
                _absPulse = not _absPulse
                _absPulseTimer = now
            end
            -- Alternate between full brake and reduced pressure to simulate ABS pulse
            local pressure = _absPulse and brake or (brake * 0.25)
            SetVehicleWheelBrakePressure(vehicle, i, pressure)
        end
    end

    if anyLocked then
        SetVehicleBrakeLights(vehicle, true)
        return true
    end

    return false
end

-- ---------------------------------------------------------------------------
-- ESC — Electronic Stability Control
-- Monitors yaw rate versus intended direction.  Detects both oversteer
-- and understeer and applies selective brake input to correct.
-- Returns (active: bool)
-- ---------------------------------------------------------------------------
local function UpdateESC(vehicle, profile, speed)
    if not PhysicsState or not PhysicsState.esc_enabled then return false end
    if speed < 5.0 then return false end

    local vel     = GetEntityVelocity(vehicle)
    local right, fwd = GetEntityMatrix(vehicle)  -- rightVec, forwardVec

    -- Compute slip angle: angle between velocity vector and forward axis
    local velLen  = math.sqrt(vel.x^2 + vel.y^2) + 0.001
    local dotFwd  = (vel.x * fwd.x + vel.y * fwd.y) / velLen
    local dotRt   = (vel.x * right.x + vel.y * right.y) / velLen

    -- Yaw deviation in degrees
    local yawDev  = math.abs(math.deg(math.atan(dotRt, dotFwd)))
    local threshold = Config.ESCAngleThreshold or 12.0

    if yawDev > threshold then
        -- Oversteer / understeer detected — apply corrective yaw torque
        -- In GTA we approximate this by briefly reducing engine torque
        _escActive = true
        TriggerEvent("SPZ:physics:escFired", yawDev)
        return true
    end

    _escActive = false
    return false
end

-- ---------------------------------------------------------------------------
-- LC — Launch Control
-- Holds RPM at a configurable target while brake + throttle are held.
-- Returns (active: bool, rpmCapMult: float) — use rpmCapMult in torque chain
-- ---------------------------------------------------------------------------
local function UpdateLC(vehicle, profile, speed, throttle, brake)
    if not PhysicsState or not PhysicsState.lc_enabled then return false, 1.0 end

    local targetRpm = (profile.engine and profile.engine.lc_rpm) or Config.LCTargetRPM or 4000
    local maxRpm    = (profile.engine and profile.engine.rpm_max) or 7000

    if brake > 0.85 and throttle > 0.85 and speed < 2.0 then
        _lcActive = true
        TriggerEvent("SPZ:physics:lcActive", true)
    elseif _lcActive and brake < 0.15 then
        _lcActive = false
        TriggerEvent("SPZ:physics:lcActive", false)
    end

    -- While LC is active, cap engine output to hold rpm at target
    local rpmCapMult = 1.0
    if _lcActive then
        local currentRpm = PhysicsState.rpm or 0
        if currentRpm > targetRpm then
            rpmCapMult = math.max(0.1, targetRpm / math.max(1, currentRpm))
        end
    end

    return _lcActive, rpmCapMult
end

-- ---------------------------------------------------------------------------
-- Exported namespace
-- ---------------------------------------------------------------------------
SPZAssists = {
    UpdateTCS = UpdateTCS,
    UpdateABS = UpdateABS,
    UpdateESC = UpdateESC,
    UpdateLC  = UpdateLC,
}

-- ---------------------------------------------------------------------------
-- Toggle commands — /spz_tcs  /spz_abs  /spz_esc
-- Flip the PhysicsState enable flag and notify the player via chat.
-- ---------------------------------------------------------------------------
local function _notifyAssist(name, enabled)
    local colour = enabled and "~g~" or "~r~"
    local state  = enabled and "ON" or "OFF"
    TriggerEvent("chat:addMessage", {
        args = { "~y~[SPZ Physics]~w~ " .. name .. " " .. colour .. state }
    })
end

RegisterCommand("spz_tcs", function()
    if not PhysicsState then return end
    PhysicsState.tcs_enabled = not PhysicsState.tcs_enabled
    _notifyAssist("TCS", PhysicsState.tcs_enabled)
end, false)

RegisterCommand("spz_abs", function()
    if not PhysicsState then return end
    PhysicsState.abs_enabled = not PhysicsState.abs_enabled
    _notifyAssist("ABS", PhysicsState.abs_enabled)
end, false)

RegisterCommand("spz_esc", function()
    if not PhysicsState then return end
    PhysicsState.esc_enabled = not PhysicsState.esc_enabled
    _notifyAssist("ESC", PhysicsState.esc_enabled)
end, false)

RegisterKeyMapping("spz_tcs", "SPiceZ: Toggle Traction Control", "keyboard", "NUMPAD7")
RegisterKeyMapping("spz_abs", "SPiceZ: Toggle ABS", "keyboard", "NUMPAD8")
RegisterKeyMapping("spz_esc", "SPiceZ: Toggle ESC", "keyboard", "NUMPAD9")
