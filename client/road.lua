-- client/road.lua
-- Dynamic road wetness simulation.
-- Tracks an accumulated wetness value (0–1) that rises during rain events
-- and slowly dries out when the weather clears.  Also provides the active
-- weather-based grip modifier from Config.WeatherGrip.

SPZRoad = {}

local _wetness       = 0.0   -- current road wetness (0 = bone dry, 1 = soaked)
local _lastUpdate    = 0     -- GetGameTimer() at last Tick call
local _weatherName   = "EXTRASUNNY"
local _isRaining     = false

-- ---------------------------------------------------------------------------
-- Internal: resolve the weather name string from GTA's native weather index.
-- ---------------------------------------------------------------------------
local WEATHER_INDEX_MAP <const> = {
    [0]  = "EXTRASUNNY",
    [1]  = "CLEAR",
    [2]  = "CLOUDS",
    [3]  = "SMOG",
    [4]  = "FOGGY",
    [5]  = "OVERCAST",
    [6]  = "RAIN",
    [7]  = "THUNDER",
    [8]  = "CLEARING",
    [9]  = "NEUTRAL",
    [10] = "SNOW",
    [11] = "BLIZZARD",
    [12] = "SNOWLIGHT",
    [13] = "XMAS",
    [14] = "HALLOWEEN",
    [15] = "HAZY",
}

local function _readWeatherName()
    -- Prefer a server-pushed GlobalState value if available (e.g. from spz-weather)
    local gs = GlobalState and GlobalState["spz:weather"]
    if gs and type(gs) == "string" then
        return string.upper(gs)
    end
    -- Fall back to GTA's own weather integer
    local idx = GetWeatherTypeTransition()  -- returns current & next; we want current
    -- GetWeatherTypeTransition returns (prevHash, nextHash, transition) —
    -- use a direct name check instead
    local _, _, _, weatherName = GetWeatherTypeTransition()
    if weatherName and weatherName ~= "" then
        return string.upper(weatherName)
    end
    -- Last resort: map integer
    local rawIdx = GetPrevWeatherTypeHashName()  -- returns name string in some builds
    return WEATHER_INDEX_MAP[0] -- safe fallback
end

-- ---------------------------------------------------------------------------
-- Internal: check if current weather is actively precipitating
-- ---------------------------------------------------------------------------
local function _checkRaining(name)
    local wetWeather = Config.RoadConditions.wetWeather
    for _, w in ipairs(wetWeather) do
        if w == name then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Public: update wetness state.  Call every frame (or at your desired rate)
-- from tick.lua.  dt should be seconds elapsed since last call.
-- ---------------------------------------------------------------------------
function SPZRoad.Tick(dt)
    local cfg = Config.RoadConditions

    -- Re-read weather every ~2 seconds to keep cost low
    local now = GetGameTimer()
    if (now - _lastUpdate) >= 2000 then
        _weatherName = _readWeatherName()
        -- Direct hash check for raining weather
        local rainHash = GetHashKey("RAIN")
        local thunderHash = GetHashKey("THUNDER")
        local clearingHash = GetHashKey("CLEARING")
        
        local curWeather = GetPrevWeatherTypeHashName()
        _isRaining = (curWeather == rainHash or curWeather == thunderHash or curWeather == clearingHash)
        _lastUpdate  = now
    end

    -- Clamp dt to avoid spikes on frame stutters
    local safeDt = math.min(dt, 1.0)

    if _isRaining then
        _wetness = math.min(cfg.maxWetness, _wetness + cfg.wetAccumRate * safeDt)
    else
        _wetness = math.max(0.0, _wetness - cfg.wetDecayRate * safeDt)
    end
end

-- ---------------------------------------------------------------------------
-- Public getters
-- ---------------------------------------------------------------------------

-- Current road wetness value in [0, 1]
function SPZRoad.GetWetness()
    return _wetness
end

-- Current weather name string (uppercased)
function SPZRoad.GetWeatherName()
    return _weatherName
end

-- Grip multiplier from the active weather type (from Config.WeatherGrip)
function SPZRoad.GetWeatherGripMod()
    local entry = Config.WeatherGrip[_weatherName] or Config.WeatherGrip.default
    return entry.grip
end

-- Combined road grip modifier accounting for both weather and accumulated wetness.
-- At full wetness the weather grip modifier is applied at full strength;
-- at zero wetness the modifier is 1.0 (dry).
function SPZRoad.GetCombinedGripMod()
    local weatherMod = SPZRoad.GetWeatherGripMod()
    -- Lerp: as wetness increases the weather grip penalty is fully applied
    return 1.0 + (_wetness * (weatherMod - 1.0))
end

-- True when weather is actively adding wetness
function SPZRoad.IsRaining()
    return _isRaining
end

-- Resets state (call on resource stop or weather override)
function SPZRoad.Reset()
    _wetness    = 0.0
    _isRaining  = false
    _lastUpdate = 0
end
