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

-- ---------------------------------------------------------------------------
-- Internal: gather a complete snapshot from all live systems
-- ---------------------------------------------------------------------------
local function _buildPayload(vehicle, state)
    local speed     = GetEntitySpeed(vehicle)
    local speedKph  = speed * 3.6
    local speedMph  = speed * 2.23694

    -- G-force via velocity-delta approximation
    local vel       = GetEntityVelocity(vehicle)
    local fwd       = GetEntityForwardVector(vehicle)
    local right     = GetEntityRightVector(vehicle)
    local longG     = fwd.x * vel.x + fwd.y * vel.y + fwd.z * vel.z
    local latG      = right.x * vel.x + right.y * vel.y + right.z * vel.z

    -- Suspension compression per corner (0=uncompressed, 1=fully compressed)
    local susp = {}
    for i = 0, 3 do
        susp[i + 1] = GetVehicleWheelSuspensionCompression(vehicle, i)
    end

    -- Tire temps / wear from thermals module
    local temps = SPZThermals.GetTemps()
    local wear  = SPZThermals.GetWear()
    local blown = SPZThermals.GetBlown()

    -- Steering angle
    local steerAngle = GetVehicleSteeringAngle(vehicle)

    -- Throttle / brake inputs
    local throttle = GetControlValue(0, 71) / 127.0
    local brake    = GetControlValue(0, 72) / 127.0

    -- Road / surface info
    local wetness      = SPZRoad.GetWetness()
    local weatherName  = SPZRoad.GetWeatherName()
    local surfGrip     = SPZSurface.GetOverallGrip()

    -- Damage HP
    local engineHP = GetVehicleEngineHealth(vehicle)
    local bodyHP   = GetVehicleBodyHealth(vehicle)

    return {
        -- Speed
        speedKph    = math.floor(speedKph),
        speedMph    = math.floor(speedMph),

        -- Drivetrain
        gear        = state.gear or GetVehicleCurrentGear(vehicle),
        rpm         = state.rpm or 0,
        rpmMin      = state.profile and state.profile.engine.rpm_min or 1000,
        rpmMax      = state.profile and state.profile.engine.rpm_max or 7000,
        boost       = state.boost_bar or 0.0,

        -- Assists
        tcsActive   = state.tcs_active or false,
        absActive   = state.abs_active or false,
        escActive   = state.esc_active or false,
        lcActive    = state.lc_active  or false,

        -- G-forces (m/s → normalise to Earth g)
        latG        = math.floor((latG  / 9.81) * 100) / 100,
        longG       = math.floor((longG / 9.81) * 100) / 100,

        -- Suspension compression (FL, FR, RL, RR)
        suspFL      = math.floor(susp[1] * 100),
        suspFR      = math.floor(susp[2] * 100),
        suspRL      = math.floor(susp[3] * 100),
        suspRR      = math.floor(susp[4] * 100),

        -- Steering
        steerAngle  = math.floor(steerAngle),

        -- Inputs
        throttle    = math.floor(throttle * 100),
        brake       = math.floor(brake    * 100),

        -- Tire thermals (°C × 10 rounded to 1dp)
        tempFL      = math.floor(temps[1] * 10) / 10,
        tempFR      = math.floor(temps[2] * 10) / 10,
        tempRL      = math.floor(temps[3] * 10) / 10,
        tempRR      = math.floor(temps[4] * 10) / 10,
        wearFL      = math.floor(wear[1] * 100),
        wearFR      = math.floor(wear[2] * 100),
        wearRL      = math.floor(wear[3] * 100),
        wearRR      = math.floor(wear[4] * 100),
        blownFL     = blown[1],
        blownFR     = blown[2],
        blownRL     = blown[3],
        blownRR     = blown[4],

        -- Road / environment
        wetness     = math.floor(wetness * 100),
        weather     = weatherName,
        surfGrip    = math.floor(surfGrip * 100),

        -- Health
        engineHP    = math.floor(engineHP),
        bodyHP      = math.floor(bodyHP),

        -- Meta
        mode        = MODES[_modeIndex],
        visible     = _visible,

        -- Slipstream
        inDraft     = SPZAero.IsInDraft(),
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
            _modeIndex = (_modeIndex % #MODES) + 1
            
            SendNUIMessage({
                action = "cycle",
                mode = MODES[_modeIndex],
                page = _modeIndex
            })

            TriggerEvent("SPZ:telemetry:mode", MODES[_modeIndex])
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
