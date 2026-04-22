-- client/telemetry.lua
-- Live physics telemetry HUD bridge.
-- Collects data from all subsystems and pushes it to the NUI frontend
-- via SendNUIMessage.  Visibility is toggled with PageUp; display mode
-- is cycled with PageDown.

SPZTelemetry = {}

local _visible    = false
local _modeIndex  = 1
local _lastUpdate = 0

local MODES <const> = { "full", "temps", "minimal" }

local _lastVel = vector3(0,0,0)
local _lastG   = { x = 0.0, y = 0.0 }

-- ---------------------------------------------------------------------------
-- Internal: gather a complete snapshot from all live systems
-- ---------------------------------------------------------------------------
local function _buildPayload(vehicle, state)
    local speed     = GetEntitySpeed(vehicle)
    local speedMph  = speed * 2.23694

    -- Proper G-force via acceleration (delta-v / dt)
    local vel       = GetEntityVelocity(vehicle)
    local dt        = (GetFrameTime() > 0) and GetFrameTime() or 0.01
    
    local accel     = (vel - _lastVel) / (dt * 9.81) -- Acceleration in Gs
    _lastVel = vel

    local fwd       = GetEntityForwardVector(vehicle)
    local right     = GetEntityRightVector(vehicle)
    
    -- Project acceleration onto vehicle axes
    local longG     = accel.x * fwd.x + accel.y * fwd.y + accel.z * fwd.z
    local latG      = accel.x * right.x + accel.y * right.y + accel.z * right.z

    -- Smoothing for G-meter
    _lastG.x = _lastG.x + (latG - _lastG.x) * 0.15
    _lastG.y = _lastG.y + (longG - _lastG.y) * 0.15

    -- Suspension compression per corner
    local susp = {}
    for i = 0, 3 do
        susp[i + 1] = GetVehicleWheelSuspensionCompression(vehicle, i)
    end

    -- Tire temps / wear
    local temps = SPZThermals.GetTemps()
    local wear  = SPZThermals.GetWear()
    local blown = SPZThermals.GetBlown()

    -- Steering angle (Native returns degrees, usually -40 to 40)
    local steerAngle = GetVehicleSteeringAngle(vehicle)

    -- Inputs
    local throttle = GetDisabledControlNormal(0, 71)
    local brake    = GetDisabledControlNormal(0, 72)

    -- Road / surface info
    local wetness      = SPZRoad.GetWetness()
    local surfGrip     = SPZSurface.GetOverallGrip()

    -- Health
    local engineHP = GetVehicleEngineHealth(vehicle)
    local bodyHP   = GetVehicleBodyHealth(vehicle)

    return {
        -- Speed
        speedMph    = math.floor(speedMph),

        -- Drivetrain
        gear        = state.gear or GetVehicleCurrentGear(vehicle),
        rpm         = state.rpm or 0,
        rpmMax      = state.profile and state.profile.engine.rpm_max or 7000,
        boost       = state.boost_bar or 0.0,

        -- G-forces (Smoothed)
        latG        = math.floor(_lastG.x * 100) / 100,
        longG       = math.floor(_lastG.y * 100) / 100,

        -- Suspension
        suspFL      = math.floor(susp[1] * 100),
        suspFR      = math.floor(susp[2] * 100),
        suspRL      = math.floor(susp[3] * 100),
        suspRR      = math.floor(susp[4] * 100),

        -- Steering
        steerAngle  = math.floor(steerAngle),

        -- Inputs
        throttle    = math.floor(throttle * 100),
        brake       = math.floor(brake    * 100),

        -- Tire thermals
        tempFL      = math.floor(temps[1] * 10) / 10,
        tempFR      = math.floor(temps[2] * 10) / 10,
        tempRL      = math.floor(temps[3] * 10) / 10,
        tempRR      = math.floor(temps[4] * 10) / 10,

        -- Road
        wetness     = math.floor(wetness * 100),
        surfGrip    = math.floor(surfGrip * 100),

        -- Health
        engineHP    = math.floor(engineHP),
        bodyHP      = math.floor(bodyHP),
    }
end

-- ---------------------------------------------------------------------------
-- Public: update telemetry — call from tick.lua
-- ---------------------------------------------------------------------------
function SPZTelemetry.Tick(vehicle, state)
    local cfg = Config.Telemetry
    if not cfg.enabled then return end

    local now      = GetGameTimer()
    local interval = _visible and cfg.activeUpdateMs or cfg.idleUpdateMs

    if (now - _lastUpdate) < interval then return end
    _lastUpdate = now

    local payload = _buildPayload(vehicle, state)
    
    -- Local trigger for other scripts
    TriggerEvent("SPZ:telemetry:update", payload)

    -- NUI update
    if _visible then
        SendNUIMessage({
            action = "update",
            data = payload
        })
    end
end

-- ---------------------------------------------------------------------------
-- Toggle / cycle key handlers & Commands
-- ---------------------------------------------------------------------------
RegisterCommand("telemetry", function()
    local cfg = Config.Telemetry
    if not cfg.enabled then return end

    _visible = not _visible
    
    SendNUIMessage({
        action = "toggle",
        show = _visible
    })

    TriggerEvent("SPZ:telemetry:toggle", _visible)
end, false)

RegisterCommand("telepage", function()
    local cfg = Config.Telemetry
    if not cfg.enabled or not _visible then return end

    _modeIndex = (_modeIndex % #MODES) + 1
    
    SendNUIMessage({
        action = "cycle",
        mode = MODES[_modeIndex],
        page = _modeIndex
    })

    TriggerEvent("SPZ:telemetry:mode", MODES[_modeIndex])
end, false)

CreateThread(function()
    while true do
        Wait(0)
        local cfg = Config.Telemetry
        if not cfg.enabled then Wait(500) goto continue end

        -- Toggle visibility
        if IsDisabledControlJustPressed(0, cfg.toggleKey) or IsControlJustPressed(0, cfg.toggleKey) then
            ExecuteCommand("telemetry")
        end

        -- Cycle display mode (Pages)
        if _visible and (IsDisabledControlJustPressed(0, cfg.cycleKey) or IsControlJustPressed(0, cfg.cycleKey)) then
            ExecuteCommand("telepage")
        end

        ::continue::
    end
end)

-- ---------------------------------------------------------------------------
-- Public getters
-- ---------------------------------------------------------------------------
function SPZTelemetry.IsVisible()
    return _visible
end

function SPZTelemetry.GetMode()
    return MODES[_modeIndex]
end

function SPZTelemetry.Reset()
    _visible   = false
    _modeIndex = 1
    _lastUpdate = 0
end
