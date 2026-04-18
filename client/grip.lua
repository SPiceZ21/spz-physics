-- client/grip.lua
-- Multi-stage traction application pipeline.
-- Assembles a final grip scalar from all contributing systems and writes
-- it directly to the vehicle's handling floats each tick.
--
-- Pipeline stages (applied in order):
--   1.  Surface material grip (from SPZSurface)
--   2.  Road wetness / weather penalty (from SPZRoad)
--   3.  Tire compound base grip (from TireData via profile.tyre)
--   4.  Tire thermal modifier (from SPZThermals)
--   5.  Aerodynamic downforce bonus (from SPZAero — if loaded)
--   6.  Vehicle damage penalty (from SPZDamage)
--   7.  Vehicle class off-road penalty
--   8.  Hard floor for dry pavement (road cars never fall below stock on tarmac)
--   9.  Final clamp to [minGrip, 1.5]

SPZGrip = {}

-- Cache of original handling values per entity (keyed by vehicle entity)
local _origCache = {}

-- Reference surface grip coefficient (dry tarmac) used to normalise the
-- surface grip into a ratio that can be blended with compound values.
local TARMAC_REFERENCE <const> = 0.90

-- GTA vehicle classes considered "off-road" — receive extra grip on dirt
local OFFROAD_CLASSES <const> = { [1]=true, [6]=true, [7]=true, [9]=true }

-- Minimum final grip multiplier (even in the worst combined conditions)
local GRIP_FLOOR <const> = 0.12

-- ---------------------------------------------------------------------------
-- Internal: cache original handling floats for a vehicle so we can restore
-- them after the player exits.
-- ---------------------------------------------------------------------------
local function _cacheOriginals(vehicle)
    if _origCache[vehicle] then return end
    _origCache[vehicle] = {
        tractionMax = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax"),
        tractionMin = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin"),
        tractionLoss = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionLossMult"),
    }
end

-- ---------------------------------------------------------------------------
-- Internal: check network ownership before writing handling floats
-- ---------------------------------------------------------------------------
local function _isOwner(vehicle)
    return NetworkGetEntityOwner(vehicle) == PlayerId()
end

-- ---------------------------------------------------------------------------
-- Public: apply the grip pipeline.
-- Returns the final combined grip multiplier.
-- ---------------------------------------------------------------------------
function SPZGrip.Apply(vehicle, profile, aeroGripBonus, damageGripMod)
    if not DoesEntityExist(vehicle) then return 1.0 end
    if not _isOwner(vehicle) then return 1.0 end

    _cacheOriginals(vehicle)
    local orig = _origCache[vehicle]

    -- ── Stage 1: Surface material grip ─────────────────────────────────────
    local surfaceGrip = SPZSurface.GetOverallGrip()  -- absolute (0–1)
    local surfaceRatio = surfaceGrip / TARMAC_REFERENCE  -- relative to reference

    -- ── Stage 2: Road wetness / weather ────────────────────────────────────
    local roadMod = SPZRoad.GetCombinedGripMod()  -- 0.3–1.0

    -- ── Stage 3: Tire compound base peak grip ───────────────────────────────
    local compound = TireData[profile.tyre] or TireData["street"]
    local compoundPeak = compound.max_g or 1.0  -- lateral G peak

    -- Normalise: stock GTA grip = 1.0, convert compound max_g to a multiplier
    -- Street tires (max_g ≈ 1.10) → ~1.0x, Slick (max_g ≈ 2.0) → ~1.82x
    local compoundMult = compoundPeak / 1.10

    -- ── Stage 4: Thermal modifier ────────────────────────────────────────────
    local thermalMod = SPZThermals.GetGripMod()  -- 0–1

    -- ── Stage 5: Aero downforce bonus (additive) ─────────────────────────────
    local aeroBonus = aeroGripBonus or 0.0

    -- ── Stage 6: Damage penalty ──────────────────────────────────────────────
    local damageMod = damageGripMod or 1.0

    -- ── Stage 7: Off-road class bonus ────────────────────────────────────────
    local vehClass   = GetVehicleClass(vehicle)
    local classBonus = OFFROAD_CLASSES[vehClass] and 0.15 or 0.0
    -- Off-road vehicles gain grip advantage on loose surfaces
    local offRoadSurf = surfaceGrip < 0.60  -- loose material
    local classMod   = offRoadSurf and (1.0 + classBonus) or 1.0

    -- ── Assemble multiplicative chain ────────────────────────────────────────
    local combinedMult = surfaceRatio * roadMod * compoundMult * thermalMod * damageMod * classMod

    -- ── Stage 8: Hard floor on dry tarmac (road cars never worse than stock) ──
    local isDryTarmac = surfaceGrip >= TARMAC_REFERENCE and SPZRoad.GetWetness() < 0.05
    if isDryTarmac then
        combinedMult = math.max(1.0, combinedMult)
    end

    -- ── Stage 9: Final clamp ──────────────────────────────────────────────────
    local finalMult = math.max(GRIP_FLOOR, math.min(2.2, combinedMult + aeroBonus))

    -- ── Apply to handling floats ──────────────────────────────────────────────
    local newMax = math.max(GRIP_FLOOR, orig.tractionMax * finalMult)
    local newMin = math.max(GRIP_FLOOR * 0.8, orig.tractionMin * finalMult)

    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", newMax)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin", newMin)

    return finalMult
end

-- ---------------------------------------------------------------------------
-- Public: restore original handling floats on vehicle exit
-- ---------------------------------------------------------------------------
function SPZGrip.Restore(vehicle)
    local orig = _origCache[vehicle]
    if not orig then return end
    if DoesEntityExist(vehicle) then
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax",  orig.tractionMax)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin",  orig.tractionMin)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionLossMult",  orig.tractionLoss)
    end
    _origCache[vehicle] = nil
end

-- Purge entire cache (resource stop)
function SPZGrip.Reset()
    _origCache = {}
end
