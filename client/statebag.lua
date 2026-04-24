-- client/statebag.lua
--
-- Problem: SyncPhysicsStateToBag was called every frame and wrote 16 state bag
-- keys unconditionally. At 60 fps that's ~960 client→server updates per second,
-- which blows past FiveM's 75/s rate limiter and causes dropped updates + spam.
--
-- Fix strategy:
--   1. Static profile values (rpm_min/max, gear_count, pp, top_speed, assist
--      enable flags) are written ONCE when the profile first loads, never again
--      unless the profile changes.
--   2. Dynamic values (rpm, gear, boost, assist active flags) are written only
--      when they change beyond a meaningful threshold AND at most every 50ms.
--   This keeps updates well below ~15/s under normal driving.

local _lastSyncMs    = 0
local SYNC_MIN_MS    = 50   -- max 20 Hz for any dynamic key

-- Previous dynamic values (for delta detection)
local _prev = {
    rpm        = -1,
    gear       = -1,
    boost      = -1.0,
    tcs_active = nil,
    abs_active = nil,
    esc_active = nil,
    lc_active  = nil,
}

-- RPM threshold: only push when RPM changes by more than this
local RPM_THRESHOLD   = 50
local BOOST_THRESHOLD = 0.02

-- Static keys pushed once per profile load
local _lastProfileSig = nil

local function _profileSig(state)
    -- Cheap fingerprint: engine rpm_min + rpm_max + gearbox.gears
    if not state or not state.profile then return nil end
    local e = state.profile.engine   or {}
    local g = state.profile.gearbox  or {}
    return tostring(e.rpm_min) .. "_" .. tostring(e.rpm_max) .. "_" .. tostring(g.gears)
end

local function _pushStaticKeys(state)
    local e = state.profile.engine   or {}
    local g = state.profile.gearbox  or {}
    LocalPlayer.state:set("physics:rpm_min",    e.rpm_min  or 1000,  true)
    LocalPlayer.state:set("physics:rpm_max",    e.rpm_max  or 7000,  true)
    LocalPlayer.state:set("physics:gear_count", g.gears    or 6,     true)
    LocalPlayer.state:set("physics:pp",         state.pp   or 0.0,   true)
    LocalPlayer.state:set("physics:top_speed",  state.top_speed or 250, true)
    -- Enable flags only change via /spz_tcs etc — treat them as static too
    LocalPlayer.state:set("physics:tcs_enabled", state.tcs_enabled ~= false, true)
    LocalPlayer.state:set("physics:abs_enabled", state.abs_enabled ~= false, true)
    LocalPlayer.state:set("physics:esc_enabled", state.esc_enabled ~= false, true)
end

function SyncPhysicsStateToBag(state)
    if not state then
        if _lastProfileSig ~= nil then
            -- Only clear on first nil call (vehicle exited)
            _lastProfileSig = nil
            _prev.rpm = -1; _prev.gear = -1; _prev.boost = -1.0
            _prev.tcs_active = nil; _prev.abs_active = nil
            _prev.esc_active = nil; _prev.lc_active  = nil
            LocalPlayer.state:set("physics:loaded", false, true)
        end
        return
    end

    local now = GetGameTimer()

    -- Push loaded flag and static keys only when profile changes
    local sig = _profileSig(state)
    if sig ~= _lastProfileSig then
        _lastProfileSig = sig
        LocalPlayer.state:set("physics:loaded", true, true)
        _pushStaticKeys(state)
        -- Reset prev so dynamic keys get a full write next tick
        _prev.rpm = -1; _prev.gear = -1; _prev.boost = -1.0
        _prev.tcs_active = nil; _prev.abs_active = nil
        _prev.esc_active = nil; _prev.lc_active  = nil
    end

    -- Rate-gate: skip dynamic writes if called too soon
    if (now - _lastSyncMs) < SYNC_MIN_MS then return end
    _lastSyncMs = now

    -- Dynamic: RPM
    local rpm = state.rpm or 0
    if math.abs(rpm - _prev.rpm) >= RPM_THRESHOLD then
        _prev.rpm = rpm
        LocalPlayer.state:set("physics:rpm", rpm, true)
    end

    -- Dynamic: Gear
    local gear = state.gear or 0
    if gear ~= _prev.gear then
        _prev.gear = gear
        LocalPlayer.state:set("physics:gear", gear, true)
    end

    -- Dynamic: Boost
    local boost = state.boost_bar or 0.0
    if math.abs(boost - _prev.boost) >= BOOST_THRESHOLD then
        _prev.boost = boost
        LocalPlayer.state:set("physics:boost", boost, true)
    end

    -- Dynamic: Assist active flags (boolean — write only on change)
    local tcs = state.tcs_active or false
    if tcs ~= _prev.tcs_active then
        _prev.tcs_active = tcs
        LocalPlayer.state:set("physics:tcs_active", tcs, true)
    end

    local abs = state.abs_active or false
    if abs ~= _prev.abs_active then
        _prev.abs_active = abs
        LocalPlayer.state:set("physics:abs_active", abs, true)
    end

    local esc = state.esc_active or false
    if esc ~= _prev.esc_active then
        _prev.esc_active = esc
        LocalPlayer.state:set("physics:esc_active", esc, true)
    end

    local lc = state.lc_active or false
    if lc ~= _prev.lc_active then
        _prev.lc_active = lc
        LocalPlayer.state:set("physics:lc_active", lc, true)
    end
end

function ClearPhysicsStateBag()
    _lastProfileSig = nil
    _prev.rpm = -1; _prev.gear = -1; _prev.boost = -1.0
    _prev.tcs_active = nil; _prev.abs_active = nil
    _prev.esc_active = nil; _prev.lc_active  = nil

    LocalPlayer.state:set("physics:loaded",    false, true)
    LocalPlayer.state:set("physics:rpm",       0,     true)
    LocalPlayer.state:set("physics:gear",      0,     true)
    LocalPlayer.state:set("physics:boost",     0.0,   true)
    LocalPlayer.state:set("physics:tcs_active", false, true)
    LocalPlayer.state:set("physics:abs_active", false, true)
end
