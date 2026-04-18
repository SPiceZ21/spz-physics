-- client/surface.lua
-- Ground material detection via per-wheel downward raycasting.
-- Samples up to 4 wheel positions and resolves the grip coefficient
-- for the detected material.  The weakest wheel determines overall traction.

SPZSurface = {}

-- Bone names used to anchor each raycast origin
local WHEEL_BONES <const> = { "wheel_lf", "wheel_rf", "wheel_lb", "wheel_rb" }

-- Cache of last known grip values per wheel index (0 = FL, 1 = FR, 2 = RL, 3 = RR)
local _wheelGrip    = { 1.0, 1.0, 1.0, 1.0 }
local _overallGrip  = 1.0
local _lastScanTime = 0

-- ---------------------------------------------------------------------------
-- Internal: look up grip coefficients for a material hash.
-- Falls back to Config.SurfaceGrip.default if hash is unmapped.
-- ---------------------------------------------------------------------------
local function _resolveGrip(matHash, wetness)
    local entry = Config.SurfaceGrip[matHash] or Config.SurfaceGrip.default
    -- Linearly blend dry and wet grip based on current road wetness (0–1)
    return entry.dry + (entry.wet - entry.dry) * math.min(1.0, wetness)
end

-- ---------------------------------------------------------------------------
-- Internal: fire a synchronous downward raycast from the given world position.
-- Returns (hit: bool, materialHash: int)
-- ---------------------------------------------------------------------------
local function _castDown(origin, rayLen)
    local dest = vector3(origin.x, origin.y, origin.z - rayLen)
    local rayHandle = StartShapeTestRay(origin.x, origin.y, origin.z,
                                        dest.x,   dest.y,   dest.z,
                                        1, -- flag: test against static world
                                        0, 7)
    local _, hit, _, _, materialHash = GetShapeTestResultIncludingMaterial(rayHandle)
    return hit == 1, materialHash
end

-- ---------------------------------------------------------------------------
-- Public: update wheel grip readings for the given vehicle.
-- Call once per surface scan interval from tick.lua.
-- ---------------------------------------------------------------------------
function SPZSurface.Scan(vehicle, wetness)
    local cfg = Config.SurfaceDetection
    if not cfg.enabled then return end

    local now = GetGameTimer()
    if (now - _lastScanTime) < cfg.scanIntervalMs then return end
    _lastScanTime = now

    local wet = wetness or 0.0

    if cfg.usePerWheel then
        -- Sample each wheel bone in sequence
        for idx, boneName in ipairs(WHEEL_BONES) do
            local boneIdx = GetEntityBoneIndexByName(vehicle, boneName)
            if boneIdx ~= -1 then
                local bonePos = GetWorldPositionOfEntityBone(vehicle, boneIdx)
                -- Offset upward slightly so the ray starts above the wheel contact patch
                local origin = vector3(bonePos.x, bonePos.y, bonePos.z + 0.3)
                local hit, matHash = _castDown(origin, cfg.castLength)
                if hit then
                    _wheelGrip[idx] = _resolveGrip(matHash, wet)
                end
                -- No hit → retain last known value (vehicle may be briefly airborne)
            end
        end
    else
        -- Centre-of-mass single ray (cheaper but less accurate)
        local pos = GetEntityCoords(vehicle)
        local origin = vector3(pos.x, pos.y, pos.z + 0.3)
        local hit, matHash = _castDown(origin, cfg.castLength)
        local g = hit and _resolveGrip(matHash, wet) or _overallGrip
        for i = 1, 4 do _wheelGrip[i] = g end
    end

    -- Overall grip = minimum across all wheels (weakest link principle)
    _overallGrip = math.min(_wheelGrip[1], _wheelGrip[2], _wheelGrip[3], _wheelGrip[4])
end

-- ---------------------------------------------------------------------------
-- Public getters
-- ---------------------------------------------------------------------------

-- Returns the minimum grip coefficient across all sampled wheels (0–1)
function SPZSurface.GetOverallGrip()
    return _overallGrip
end

-- Returns grip per wheel: FL, FR, RL, RR (indexed 1–4)
function SPZSurface.GetWheelGrip(wheelIdx)
    return _wheelGrip[wheelIdx] or _overallGrip
end

-- Returns a copy of all four wheel grip values
function SPZSurface.GetAllWheelGrip()
    return { _wheelGrip[1], _wheelGrip[2], _wheelGrip[3], _wheelGrip[4] }
end

-- Resets cached state (call on vehicle exit)
function SPZSurface.Reset()
    for i = 1, 4 do _wheelGrip[i] = 1.0 end
    _overallGrip  = 1.0
    _lastScanTime = 0
end
