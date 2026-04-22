-- client/damage.lua
-- Collision detection and environmental vehicle damage.
-- Monitors velocity changes to detect impacts and applies proportional
-- damage to engine, body, and wheel health.  Environmental sources such
-- as submersion and sustained over-revving are also handled.
-- Network sync is broadcast to the server for replication to other clients.

SPZDamage = {}

-- Per-vehicle state (keyed by entity handle)
local _state = {}

-- ---------------------------------------------------------------------------
-- Internal: initialise or retrieve damage state for a vehicle
-- ---------------------------------------------------------------------------
local function _getState(vehicle)
    if not _state[vehicle] then
        _state[vehicle] = {
            lastVelocity  = GetEntityVelocity(vehicle),
            lastHitTime   = 0,
            gripModifier  = 1.0,
        }
    end
    return _state[vehicle]
end

-- ---------------------------------------------------------------------------
-- Internal: resolve GTA class-based damage sensitivity
-- ---------------------------------------------------------------------------
local function _classScale(vehicle)
    local cls = GetVehicleClass(vehicle)
    return Config.Damage.classScale[cls] or 1.0
end

-- ---------------------------------------------------------------------------
-- Internal: compute current grip loss from engine/body/wheel health
-- Returns a multiplier in [Config.Damage.gripLossFloor, 1.0]
-- ---------------------------------------------------------------------------
local function _computeGripMod(vehicle)
    local cfg = Config.Damage

    local engineHP = GetVehicleEngineHealth(vehicle)   -- 0–1000 stock range
    local bodyHP   = GetVehicleBodyHealth(vehicle)
    local wheelHP  = (GetVehicleWheelHealth(vehicle, 0)
                    + GetVehicleWheelHealth(vehicle, 1)
                    + GetVehicleWheelHealth(vehicle, 2)
                    + GetVehicleWheelHealth(vehicle, 3)) / 4.0

    -- Normalise each component to [0, 1] loss fraction
    local engineLoss = math.max(0.0, (1000.0 - engineHP) / 1000.0)
    local bodyLoss   = math.max(0.0, (1000.0 - bodyHP)   / 1000.0)
    local wheelLoss  = math.max(0.0, (1000.0 - wheelHP)  / 1000.0)

    -- Weighted penalty (engine and wheels matter more than body)
    local totalLoss = (engineLoss * 0.40) + (wheelLoss * 0.35) + (bodyLoss * 0.25)
    local capped    = math.min(totalLoss, cfg.gripLossCap)

    return math.max(cfg.gripLossFloor, 1.0 - capped)
end

-- ---------------------------------------------------------------------------
-- Internal: broadcast damage to server for multiplayer sync
-- ---------------------------------------------------------------------------
local function _syncDamage(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local timeout = 0
    while not NetworkGetEntityIsNetworked(vehicle) and timeout < 100 do
        Wait(0)
        timeout = timeout + 1
    end

    if NetworkGetEntityIsNetworked(vehicle) then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        local engineHP  = GetVehicleEngineHealth(vehicle)
        local bodyHP    = GetVehicleBodyHealth(vehicle)
        TriggerServerEvent("SPZ:physics:damageSync", netId, engineHP, bodyHP)
    end
end

-- ---------------------------------------------------------------------------
-- Public: call every tick while driving.
-- vehicle  — entity handle
-- rpm      — current engine RPM (real value)
-- profile  — vehicle profile table
-- speed    — vehicle speed m/s
-- dt       — elapsed seconds since last call
-- ---------------------------------------------------------------------------
function SPZDamage.Tick(vehicle, rpm, profile, speed, dt)
    local cfg = Config.Damage
    if not cfg.enabled or not DoesEntityExist(vehicle) then return end

    local s   = _getState(vehicle)

    -- Skip trains, helis, planes, boats — they have no meaningful collision health
    local cls = GetVehicleClass(vehicle)
    if cls == 15 or cls == 16 or cls == 17 or cls == 21 then return end

    -- ── Collision detection via velocity delta ────────────────────────────
    local curVel  = GetEntityVelocity(vehicle)
    local velDelta = #(curVel - s.lastVelocity) / (dt + 0.001)  -- m/s² impulse magnitude

    local now = GetGameTimer()
    if velDelta >= cfg.impactSpeedThresh
    and (now - s.lastHitTime) >= cfg.hitCooldownMs then

        s.lastHitTime = now
        local scale   = _classScale(vehicle)

        -- Speed bonus: faster impacts = more damage
        local speedFactor = 1.0 + math.max(0.0, (speed - 15.0) / 30.0)

        local engDmg  = cfg.engineDmgPerHit * speedFactor * scale
        local bodyDmg = cfg.bodyDmgPerHit   * speedFactor * scale

        -- Apply damage
        local curEng  = GetVehicleEngineHealth(vehicle)
        local curBody = GetVehicleBodyHealth(vehicle)
        SetVehicleEngineHealth(vehicle, math.max(0.0, curEng  - engDmg))
        SetVehicleBodyHealth(vehicle,   math.max(0.0, curBody - bodyDmg))

        -- Random wheel damage on heavy impacts
        if velDelta >= cfg.impactSpeedThresh * 1.8 then
            local wheelIdx = math.random(0, 3)
            local curWheel = GetVehicleWheelHealth(vehicle, wheelIdx)
            SetVehicleWheelHealth(vehicle, wheelIdx, math.max(0.0, curWheel - bodyDmg * 0.5))
        end

        TriggerEvent("SPZ:physics:impactDamage", velDelta, engDmg, bodyDmg)
        _syncDamage(vehicle)
    end

    s.lastVelocity = curVel

    -- ── Environmental: water submersion ──────────────────────────────────
    local subLevel = GetEntitySubmergedLevel(vehicle)
    if subLevel > 0.4 then
        local drain = cfg.waterSinkRate * dt
        local hp    = GetVehicleEngineHealth(vehicle)
        SetVehicleEngineHealth(vehicle, math.max(0.0, hp - drain))
    end

    -- ── Environmental: over-rev damage ───────────────────────────────────
    if profile and profile.engine then
        local maxRpm   = profile.engine.rpm_limit or profile.engine.rpm_max
        if rpm >= (maxRpm * 0.97) then
            -- High-speed airflow partially cools the engine
            local isCooled = speed >= cfg.airCoolSpeedMs
            if not isCooled then
                local drain = cfg.overRevRate * dt
                local hp    = GetVehicleEngineHealth(vehicle)
                SetVehicleEngineHealth(vehicle, math.max(0.0, hp - drain))
            end
        end
    end

    -- ── Update grip modifier ──────────────────────────────────────────────
    s.gripModifier = _computeGripMod(vehicle)
end

-- ---------------------------------------------------------------------------
-- Public: returns the current damage-based grip multiplier (0–1)
-- ---------------------------------------------------------------------------
function SPZDamage.GetGripMod(vehicle)
    local s = _state[vehicle]
    return s and s.gripModifier or 1.0
end

-- ---------------------------------------------------------------------------
-- Server → client: sync damage from another player who caused the impact
-- ---------------------------------------------------------------------------
RegisterNetEvent("SPZ:physics:syncDamage")
AddEventHandler("SPZ:physics:syncDamage", function(senderSrc, netId, engineHP, bodyHP)
    if source == senderSrc then return end  -- don't overwrite our own
    if not netId then return end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end
    -- Only update if we're not the owner (owners handle their own HP)
    if NetworkGetEntityOwner(vehicle) == PlayerId() then return end
    SetVehicleEngineHealth(vehicle, engineHP)
    SetVehicleBodyHealth(vehicle,   bodyHP)
end)

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------
function SPZDamage.Reset(vehicle)
    _state[vehicle] = nil
end

function SPZDamage.ResetAll()
    _state = {}
end
