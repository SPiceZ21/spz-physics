-- client/performance.lua
-- Maps accumulated vehicle damage onto real-time handling float penalties.
-- Also applies active geometry adjustments (brake dive, acceleration squat,
-- cornering camber load) that change every physics frame.
-- All original handling values are cached on first entry so they can be
-- cleanly restored when the player exits.

SPZPerformance = {}

-- Per-vehicle cached originals keyed by entity handle
local _originals = {}
local _applied = {}

-- ---------------------------------------------------------------------------
-- Internal: cache the original handling floats we intend to modify
-- ---------------------------------------------------------------------------
local function _cacheHandling(vehicle)
    if _originals[vehicle] then return end
    local function gf(k) return GetVehicleHandlingFloat(vehicle, "CHandlingData", k) end
    _originals[vehicle] = {
        driveForce       = gf("fInitialDriveForce"),
        driveMaxFlatVel  = gf("fDriveMaxFlatVel"),
        initialDriveMaxFlatVel = gf("fInitialDriveMaxFlatVel"),
        brakeBiasFront   = gf("fBrakeBiasFront"),
        brakeForce       = gf("fBrakeForce"),
        steeringLock     = gf("fSteeringLock"),
        suspSpringStrg   = gf("fSuspensionSpringStrength"),
        suspDamping      = gf("fSuspensionDampingCompress"),
        cambFront        = gf("fCamberStiffnesss"),     -- GTA uses 3 s intentionally
        tractionFront    = gf("fTractionBiasFront"),
    }
end

-- ---------------------------------------------------------------------------
-- Internal: linear interpolation helper
-- ---------------------------------------------------------------------------
local function _lerp(a, b, t)
    return a + (b - a) * math.min(1.0, math.max(0.0, t))
end

-- ---------------------------------------------------------------------------
-- Internal: convert GTA health (0–1000) to a normalised damage fraction (0–1)
-- 0 = pristine, 1 = completely destroyed
-- ---------------------------------------------------------------------------
local function _damageFraction(health, fullThresh, critThresh)
    if health >= fullThresh then return 0.0 end
    if health <= critThresh  then return 1.0 end
    return (fullThresh - health) / (fullThresh - critThresh)
end

-- ---------------------------------------------------------------------------
-- Public: apply all damage-based handling degradation for the current frame.
-- vehicle       — entity handle
-- lateralAccel  — lateral G (unsigned m/s²)
-- longAccel     — longitudinal acceleration (+ forward, − braking) m/s²
-- speed         — speed in m/s
-- ---------------------------------------------------------------------------
function SPZPerformance.Apply(vehicle, lateralAccel, longAccel, speed)
    if not DoesEntityExist(vehicle) then return end
    if NetworkGetEntityOwner(vehicle) ~= PlayerId() then return end

    _cacheHandling(vehicle)
    local o   = _originals[vehicle]
    local cfg = Config.Performance

    if not _applied[vehicle] then _applied[vehicle] = {} end

    local function sf(k, v) 
        -- Delta check: prevents Havok re-init spam which causes wheels to disappear and vehicle to face North
        if not _applied[vehicle][k] or math.abs(_applied[vehicle][k] - v) > 0.05 then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", k, v)
            _applied[vehicle][k] = v
        end
    end

    -- Health readings
    local engineHP  = GetVehicleEngineHealth(vehicle)
    local bodyHP    = GetVehicleBodyHealth(vehicle)

    local engDmgFrac  = _damageFraction(engineHP, cfg.engineHealthFull, cfg.engineHealthCritical)
    local bodyDmgFrac = _damageFraction(bodyHP,   cfg.engineHealthFull, cfg.engineHealthCritical)

    -- ── Engine degradation ──────────────────────────────────────────────
    if engDmgFrac > 0.0 then
        local newDrive  = o.driveForce      * _lerp(1.0, cfg.enginePowerPenalty,  engDmgFrac)
        local newTopSpd = o.driveMaxFlatVel * _lerp(1.0, cfg.engineTopSpdPenalty, engDmgFrac)
        sf("fInitialDriveForce",         newDrive)
        sf("fDriveMaxFlatVel",           newTopSpd)
        sf("fInitialDriveMaxFlatVel",    newTopSpd)
    end

    -- ── Suspension / body degradation ──────────────────────────────────
    -- Modifying suspension spring/damping dynamically causes NaN physics bugs
    -- during collisions, so we no longer apply damage penalties to them.

    -- ── Steering lock reduction (speed-dependent + damage) ──────────────
    do
        local speedT   = math.min(1.0, speed / 55.0)           -- 0 at rest, 1 at 55 m/s
        local speedMod = _lerp(1.0, cfg.steeringSpeedReduction, speedT)
        local dmgMod   = _lerp(1.0, 1.0 - cfg.steeringDmgPenalty, bodyDmgFrac)
        sf("fSteeringLock", o.steeringLock * speedMod * dmgMod)
    end

    -- ── Brake force & bias degradation ─────────────────────────────────
    if bodyDmgFrac > 0.0 then
        local newBrake = o.brakeForce * _lerp(1.0, 1.0 - cfg.brakesForcePenalty, bodyDmgFrac)
        local newBias  = o.brakeBiasFront + cfg.brakesBiasShift * bodyDmgFrac
        sf("fBrakeForce",      newBrake)
        sf("fBrakeBiasFront",  math.min(0.90, newBias))
    end

    -- Active geometry (dynamic per-frame adjustments)
    -- Modifying fCamberStiffnesss based on acceleration causes NaN physics bugs
    -- during collisions due to Havok solver instability. Removed for stability.
end

-- ---------------------------------------------------------------------------
-- Public: restore all handling to cached originals
-- ---------------------------------------------------------------------------
function SPZPerformance.Restore(vehicle)
    local o = _originals[vehicle]
    if not o or not DoesEntityExist(vehicle) then
        _originals[vehicle] = nil
        return
    end
    local function sf(k, v) SetVehicleHandlingFloat(vehicle, "CHandlingData", k, v) end
    sf("fInitialDriveForce",        o.driveForce)
    sf("fDriveMaxFlatVel",          o.driveMaxFlatVel)
    sf("fInitialDriveMaxFlatVel",   o.initialDriveMaxFlatVel)
    sf("fBrakeBiasFront",           o.brakeBiasFront)
    sf("fBrakeForce",               o.brakeForce)
    sf("fSteeringLock",             o.steeringLock)
    sf("fSuspensionSpringStrength", o.suspSpringStrg)
    sf("fSuspensionDampingCompress",o.suspDamping)
    sf("fCamberStiffnesss",         o.cambFront)
    sf("fTractionBiasFront",        o.tractionFront)
    _originals[vehicle] = nil
    _applied[vehicle] = nil
end

function SPZPerformance.Reset()
    _originals = {}
    _applied = {}
end
