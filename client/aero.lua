-- client/aero.lua
-- Aerodynamic effects:
--   • Downforce   — increases grip linearly with speed above a threshold.
--   • Slipstream  — applies a continuous forward velocity push when
--                   driving directly behind a lead vehicle.
--
-- Downforce bonus is returned as a scalar for use by grip.lua.
-- Slipstream is applied directly via SetEntityVelocity impulses.

SPZAero = {}

-- Track last known slipstream state for telemetry
local _inDraft     = false
local _draftForce  = 0.0

-- ---------------------------------------------------------------------------
-- Internal: compute downforce grip bonus from vehicle speed
-- Returns an additive grip bonus (0–Config.Aero.downforceGripBonus)
-- ---------------------------------------------------------------------------
local function _calcDownforce(speed)
    local cfg = Config.Aero
    if not cfg.downforceEnabled then return 0.0 end
    if speed < cfg.downforceMinSpeedMs then return 0.0 end

    local t = math.min(1.0,
        (speed - cfg.downforceMinSpeedMs) / (cfg.downforceMaxSpeedMs - cfg.downforceMinSpeedMs))
    return t * cfg.downforceGripBonus
end

-- ---------------------------------------------------------------------------
-- Internal: shape-cast forward to detect a lead vehicle in the draft cone.
-- Returns (inDraft: bool, proximityt: float 0–1)  — 1 = touching lead car
-- ---------------------------------------------------------------------------
local function _scanSlipstream(vehicle, speed)
    local cfg = Config.Aero
    if not cfg.slipstreamEnabled then return false, 0.0 end
    if speed < cfg.slipstreamMinSpeedMs then return false, 0.0 end

    local fwd    = GetEntityForwardVector(vehicle)
    local pos    = GetEntityCoords(vehicle)
    local halfAng = math.rad(cfg.slipstreamHalfAng)

    -- Fire a shape-test ray forward from the vehicle's origin
    local destX = pos.x + fwd.x * cfg.slipstreamReach
    local destY = pos.y + fwd.y * cfg.slipstreamReach
    local destZ = pos.z + fwd.z * cfg.slipstreamReach

    local rayHandle = StartShapeTestRay(
        pos.x, pos.y, pos.z + 0.5,
        destX, destY, destZ + 0.5,
        10, -- flag: test against vehicles
        vehicle, 7)

    local _, hit, hitCoords, _, hitEntity = GetShapeTestResult(rayHandle)

    if hit ~= 1 then return false, 0.0 end
    if not IsEntityAVehicle(hitEntity) then return false, 0.0 end

    -- Verify the hit entity is actually ahead within the cone angle
    local toTarget = hitCoords - pos
    local dist     = #toTarget
    if dist < 1.0 or dist > cfg.slipstreamReach then return false, 0.0 end

    local normToTarget = toTarget / dist
    local dotFwd = normToTarget.x * fwd.x + normToTarget.y * fwd.y + normToTarget.z * fwd.z
    local angle  = math.acos(math.max(-1.0, math.min(1.0, dotFwd)))

    if angle > halfAng then return false, 0.0 end

    -- Proximity factor: 1 = right behind, 0 = at maximum range
    local proximity = 1.0 - (dist / cfg.slipstreamReach)
    return true, proximity
end

-- ---------------------------------------------------------------------------
-- Public: run full aero simulation for one frame.
-- vehicle — entity handle
-- speed   — vehicle speed in m/s
-- dt      — elapsed seconds
-- Returns downforceGripBonus (float) for use in grip.lua
-- ---------------------------------------------------------------------------
function SPZAero.Tick(vehicle, speed, dt)
    if not DoesEntityExist(vehicle) then
        _inDraft = false
        _draftForce = 0.0
        return 0.0
    end

    -- ── Downforce ──────────────────────────────────────────────────────
    local downforceBonus = _calcDownforce(speed)

    -- ── Slipstream ─────────────────────────────────────────────────────
    local inDraft, proximity = _scanSlipstream(vehicle, speed)
    _inDraft = inDraft

    if inDraft and proximity > 0.0 then
        local cfg       = Config.Aero
        local forceMag  = proximity * cfg.slipstreamPeakForce * speed * dt
        _draftForce     = forceMag

        -- Apply impulse in the vehicle's forward direction using ApplyForceToEntity
        -- to prevent Havok NaN bugs and catastrophic orientation resets
        -- forceType 1 = linear force
        ApplyForceToEntity(vehicle, 1,
            0.0, forceMag * 50.0, 0.0, -- x, y, z force (y is forward in local coords)
            0.0, 0.0, 0.0,           -- offset
            0,                       -- boneIndex
            true,                    -- isRel (local coords)
            true,                    -- ignoreUpVec
            true,                    -- isMultByMass
            false,                   -- p10
            true                     -- p11
        )
    else
        _draftForce = 0.0
    end

    return downforceBonus
end

-- ---------------------------------------------------------------------------
-- Public getters (for telemetry)
-- ---------------------------------------------------------------------------
function SPZAero.IsInDraft()
    return _inDraft
end

function SPZAero.GetDraftForce()
    return _draftForce
end

function SPZAero.Reset()
    _inDraft    = false
    _draftForce = 0.0
end
