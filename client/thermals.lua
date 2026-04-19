-- client/thermals.lua
-- Per-wheel tire temperature and wear simulation.
-- Each wheel maintains an independent thermal state.  Temperatures are
-- affected by wheel slip, braking load, cornering force, and ambient
-- conditions.  Both temperature and wear contribute a grip modifier
-- that the grip pipeline applies on top of the base compound values.

SPZThermals = {}

-- Wheel index constants (matching GTA V's wheel indices)
local FL <const>, FR <const>, RL <const>, RR <const> = 1, 2, 3, 4
local WHEEL_COUNT <const> = 4

-- Internal state arrays indexed 1–4 (FL, FR, RL, RR)
local _temp     = {}   -- °C per wheel
local _wear     = {}   -- 0 (new) → 1 (bald / failed)
local _blown    = {}   -- true if tire has blown out this session

local function _init()
    local ambient = Config.Thermals.ambientBaseTemp or 20.0
    for i = 1, WHEEL_COUNT do
        _temp[i]  = ambient
        _wear[i]  = 0.0
        _blown[i] = false
    end
end
_init()

-- ---------------------------------------------------------------------------
-- Internal: classify drivetrain so we know which wheels receive drive heat
-- ---------------------------------------------------------------------------
local function _getDrivenSet(drivetrain)
    if drivetrain == "RWD" then
        return { RL, RR }
    elseif drivetrain == "FWD" then
        return { FL, FR }
    else  -- AWD or unknown
        return { FL, FR, RL, RR }
    end
end

-- ---------------------------------------------------------------------------
-- Internal: grip modifier from temperature (0 = no grip, 1 = full grip)
-- ---------------------------------------------------------------------------
local function _tempGripMod(temp)
    local cfg = Config.Thermals

    if _blown[1] and _blown[2] and _blown[3] and _blown[4] then
        -- All tires blown — catastrophic loss
        return 0.0
    end

    if temp < cfg.coldGripStartTemp then
        -- Below optimal cold threshold — scale from (ambientBaseTemp → coldGripStartTemp)
        local t = math.max(0.0, (temp - cfg.ambientBaseTemp) / (cfg.coldGripStartTemp - cfg.ambientBaseTemp))
        return 1.0 - cfg.maxColdGripLoss * (1.0 - t)

    elseif temp >= cfg.optimalLow and temp <= cfg.optimalHigh then
        -- Inside the optimal window — full grip
        return 1.0

    elseif temp > cfg.optimalHigh and temp < cfg.hotGripStartTemp then
        -- Warm but not yet penalised
        return 1.0

    elseif temp >= cfg.hotGripStartTemp then
        -- Overheating — ramp up penalty toward blowout
        local t = math.min(1.0, (temp - cfg.hotGripStartTemp) / (cfg.blowoutThreshold - cfg.hotGripStartTemp))
        return 1.0 - cfg.maxHotGripLoss * t
    end

    return 1.0
end

-- ---------------------------------------------------------------------------
-- Public: update all wheel temperatures.
-- vehicle       — entity handle
-- drivetrain    — "FWD" | "RWD" | "AWD"
-- speed         — vehicle speed in m/s
-- throttle      — 0–1 input
-- brake         — 0–1 input
-- lateralG      — lateral G-force (unsigned)
-- dt            — seconds elapsed
-- ---------------------------------------------------------------------------
function SPZThermals.Tick(vehicle, drivetrain, speed, throttle, brake, lateralG, dt)
    local cfg    = Config.Thermals
    if not cfg.enabled then return end

    local safeDt = math.min(dt, 0.2)  -- cap to 200ms to prevent spikes
    local driven = _getDrivenSet(drivetrain)
    local drivenSet = {}
    for _, idx in ipairs(driven) do drivenSet[idx] = true end

    -- Measure wheel speeds for slip detection
    local vehSpeedMs = speed
    local brakeHeat  = brake > 0.4 and (brake * cfg.brakeHeatRate * safeDt) or 0.0
    local cornerHeat = lateralG > 0.3 and (lateralG * cfg.cornerHeatRate * safeDt) or 0.0

    for i = 1, WHEEL_COUNT do
        if _blown[i] then goto continue end

        local wheelSpd = GetVehicleWheelSpeed(vehicle, i - 1) -- GTA index 0-based
        local slipRatio = 0.0
        if vehSpeedMs > 0.5 then
            -- Clamp denominator to ≥10 m/s so low-speed launches don't spike temps instantly
            local denom = math.max(vehSpeedMs, 10.0)
            slipRatio = math.min(1.0, math.abs(wheelSpd - vehSpeedMs) / denom)
        end

        -- Heat accumulation
        local slipHeat = slipRatio * cfg.slipHeatRate * safeDt
        if not drivenSet[i] then slipHeat = slipHeat * 0.4 end  -- unpowered wheels slip less

        local totalHeat = slipHeat
            + brakeHeat
            + cornerHeat
            + (cfg.rollHeatRate * safeDt)

        -- Cooling: radiation + airflow
        local cooling = (cfg.radiationCool + speed * cfg.airflowCoolPerMs) * safeDt
        local ambient = cfg.ambientBaseTemp

        -- Temperature update — approach ambient from below when cool
        _temp[i] = _temp[i] + totalHeat - cooling
        _temp[i] = math.max(ambient, math.min(cfg.maxCapTemp, _temp[i]))

        -- Blowout check
        if _temp[i] >= cfg.blowoutThreshold then
            _blown[i] = true
            SetVehicleTyreBurst(vehicle, i - 1, true, 1000.0)
            TriggerEvent("SPZ:physics:tyreBlow", i)
        end

        -- Wear accumulation
        local wearSlip  = slipRatio > 0.08 and (cfg.wearRateSlip * safeDt) or 0.0
        local wearBrake = brake > 0.6 and (cfg.wearRateBrake * safeDt) or 0.0
        local wearDist  = vehSpeedMs * safeDt * cfg.wearRateDistance

        _wear[i] = math.min(1.0, _wear[i] + wearSlip + wearBrake + wearDist)

        -- Fully worn tires have reduced grip (handled in GetGripMod)
        if _wear[i] >= 1.0 and not _blown[i] then
            _blown[i] = true
            SetVehicleTyreBurst(vehicle, i - 1, true, 1000.0)
            TriggerEvent("SPZ:physics:tyreBlow", i)
        end

        ::continue::
    end
end

-- ---------------------------------------------------------------------------
-- Public: overall grip modifier from thermal state.
-- Returns a scalar in [0, 1] based on the coldest/hottest wheel.
-- ---------------------------------------------------------------------------
function SPZThermals.GetGripMod()
    local worst      = 1.0
    local blownCount = 0

    for i = 1, WHEEL_COUNT do
        if _blown[i] then
            blownCount = blownCount + 1
        else
            local mod     = _tempGripMod(_temp[i])
            local wearMod = 1.0 - (_wear[i] * 0.20)
            worst = math.min(worst, mod * wearMod)
        end
    end

    if blownCount > 0 then
        -- Proportional penalty: each blown tire costs 35% grip (capped at 100%)
        -- 1 blown → ×0.65, 2 → ×0.50, 3 → ×0.35, 4 → ×0.0
        local blownFactor = math.max(0.0, 1.0 - blownCount * 0.35)
        worst = worst * blownFactor
    end

    return worst
end

-- ---------------------------------------------------------------------------
-- Public getters for telemetry / HUD
-- ---------------------------------------------------------------------------
function SPZThermals.GetTemps()
    return { _temp[FL], _temp[FR], _temp[RL], _temp[RR] }
end

function SPZThermals.GetWear()
    return { _wear[FL], _wear[FR], _wear[RL], _wear[RR] }
end

function SPZThermals.GetBlown()
    return { _blown[FL], _blown[FR], _blown[RL], _blown[RR] }
end

function SPZThermals.GetWheelTemp(i)
    return _temp[i] or Config.Thermals.ambientBaseTemp
end

-- ---------------------------------------------------------------------------
-- Resets all thermal state (call on vehicle exit / new vehicle)
-- ---------------------------------------------------------------------------
function SPZThermals.Reset()
    _init()
end
