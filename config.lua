-- config.lua
Config = {}

-- ── Physics tick ──────────────────────────────────────────────────────────
Config.TickRate         = 0            -- 0 = every frame, set higher to reduce load
Config.GlobalTorqueMultiplier = 1.75   -- overall boost to all vehicles

-- ── Assists ───────────────────────────────────────────────────────────────
Config.TCSSlipThreshold = 0.25         -- wheel speed delta to trigger TCS
Config.ESCAngleThreshold= 12.0         -- degrees of yaw deviation before ESC fires
Config.LCTargetRPM      = 4000         -- default launch control hold RPM

-- ── Turbo ─────────────────────────────────────────────────────────────────
Config.TurboBoostMultiplier = 0.55     -- how much boost affects torque multiplier

-- ── Gearbox ───────────────────────────────────────────────────────────────
Config.DefaultShiftDelay    = 80       -- ms, used if profile has none

-- ── PP ────────────────────────────────────────────────────────────────────
Config.PPBrackets = {
  [0] = { min=0,  max=39  },   -- C
  [1] = { min=40, max=59  },   -- B
  [2] = { min=60, max=79  },   -- A
  [3] = { min=80, max=100 },   -- S
}

-- ── Debug ─────────────────────────────────────────────────────────────────
Config.Debug              = false
Config.DebugOverlay       = false      -- on-screen physics values during dev

-- ─────────────────────────────────────────────────────────────────────────
-- SURFACE DETECTION
-- Per-wheel ground material raycasting with grip look-up.
-- Hash values match GTA V's internal material enum.
-- ─────────────────────────────────────────────────────────────────────────
Config.SurfaceDetection = {
    enabled         = true,
    castLength      = 2.2,      -- downward ray length in GTA units
    scanIntervalMs  = 50,       -- ms between full surface reads
    usePerWheel     = true,     -- true = sample all 4 wheels; false = centre only
}

-- Material-hash → { dry grip (0–1), wet grip (0–1) }
-- Grip here is a coefficient relative to GTA's reference tarmac value.
Config.SurfaceGrip = {
    -- Tarmac / asphalt varieties
    [0x737A7A4B] = { dry = 0.97, wet = 0.67 },
    [0x6EB0A255] = { dry = 0.94, wet = 0.63 },
    [0x9B8A7463] = { dry = 0.84, wet = 0.59 },
    [0x28FB7FBD] = { dry = 0.91, wet = 0.61 },
    -- Concrete / paved surfaces
    [0x962C3F7B] = { dry = 0.90, wet = 0.60 },
    [0x867FC36C] = { dry = 0.87, wet = 0.57 },
    [0xC5AE6DAD] = { dry = 0.85, wet = 0.55 },
    -- Brick / cobble
    [0x5BEB3D9A] = { dry = 0.78, wet = 0.50 },
    -- Gravel / loose stone
    [0x7B6C5B4A] = { dry = 0.54, wet = 0.34 },
    [0x1B893968] = { dry = 0.48, wet = 0.29 },
    -- Dirt / earth tracks
    [0xA9DB53C2] = { dry = 0.88, wet = 0.65 },
    [0x55D50A03] = { dry = 0.85, wet = 0.60 },
    -- Grass / turf
    [0x7AF8B2AC] = { dry = 0.40, wet = 0.26 },
    [0xF9EBD14B] = { dry = 0.36, wet = 0.23 },
    -- Sand / beach
    [0xF7B4AB7F] = { dry = 0.36, wet = 0.21 },
    -- Mud / marsh
    [0x35B5E2BB] = { dry = 0.58, wet = 0.35 },
    [0x5D2D11B1] = { dry = 0.55, wet = 0.33 },
    -- Ice
    [0xB2D4AB6B] = { dry = 0.11, wet = 0.07 },
    [0x73817F5C] = { dry = 0.14, wet = 0.09 },
    -- Snow / slush
    [0x5B3D5B5B] = { dry = 0.22, wet = 0.14 },
    [0xA41EB89A] = { dry = 0.18, wet = 0.12 },
    -- Standing water / puddles
    [0xC5ADF65C] = { dry = 0.07, wet = 0.05 },
    -- Default fallback for unrecognised materials
    default       = { dry = 0.86, wet = 0.57 },
}

-- ─────────────────────────────────────────────────────────────────────────
-- ROAD CONDITIONS  (wetness + weather grip modifiers)
-- ─────────────────────────────────────────────────────────────────────────
Config.RoadConditions = {
    wetAccumRate    = 0.022,    -- wetness gained per second during active rain
    wetDecayRate    = 0.0008,   -- wetness lost per second when dry
    maxWetness      = 1.0,
    -- Weather names that count as "actively raining"
    wetWeather      = { "RAIN", "THUNDER", "SNOW", "XMAS", "SNOWLIGHT", "BLIZZARD" },
}

-- Weather type → { wetness baseline (0–1), grip multiplier (0–1) }
Config.WeatherGrip = {
    EXTRASUNNY  = { wetness = 0.00, grip = 1.00 },
    CLEAR       = { wetness = 0.00, grip = 1.00 },
    CLOUDS      = { wetness = 0.00, grip = 0.98 },
    OVERCAST    = { wetness = 0.05, grip = 0.96 },
    FOGGY       = { wetness = 0.10, grip = 0.91 },
    SMOG        = { wetness = 0.00, grip = 0.97 },
    HAZY        = { wetness = 0.00, grip = 0.98 },
    RAIN        = { wetness = 0.65, grip = 0.64 },
    THUNDER     = { wetness = 0.90, grip = 0.52 },
    CLEARING    = { wetness = 0.30, grip = 0.80 },
    SNOW        = { wetness = 0.60, grip = 0.47 },
    SNOWLIGHT   = { wetness = 0.40, grip = 0.54 },
    BLIZZARD    = { wetness = 1.00, grip = 0.30 },
    XMAS        = { wetness = 0.45, grip = 0.49 },
    default     = { wetness = 0.00, grip = 1.00 },
}

-- ─────────────────────────────────────────────────────────────────────────
-- TIRE THERMALS
-- Independent per-wheel temperature & wear simulation.
-- ─────────────────────────────────────────────────────────────────────────
Config.Thermals = {
    enabled             = true,
    ambientBaseTemp     = 20.0,     -- °C starting point
    optimalLow          = 70.0,     -- °C — lower bound of peak grip window
    optimalHigh         = 120.0,    -- °C — upper bound of peak grip window
    blowoutThreshold    = 155.0,    -- °C — tire failure above this
    maxCapTemp          = 160.0,    -- absolute ceiling (never exceeded)

    -- Heat generation (°C / second at the given load)
    slipHeatRate        = 22.0,     -- spinning / sliding wheels
    brakeHeatRate       = 14.0,     -- locked / heavy braking
    cornerHeatRate      = 8.0,      -- lateral cornering load
    rollHeatRate        = 0.6,      -- baseline rolling friction

    -- Cooling
    radiationCool       = 3.0,      -- ambient radiation loss at rest
    airflowCoolPerMs    = 0.18,     -- extra cooling per m/s of vehicle speed

    -- Grip window penalties
    coldGripStartTemp   = 60.0,     -- °C — penalty begins below this
    hotGripStartTemp    = 135.0,    -- °C — penalty begins above this
    maxColdGripLoss     = 0.08,     -- grip loss when ice-cold
    maxHotGripLoss      = 0.30,     -- grip loss approaching blowout

    -- Tire wear accumulation (0.0 = new → 1.0 = bald)
    wearRateSlip        = 0.0010,   -- per slip event
    wearRateBrake       = 0.0004,   -- per brake event
    wearRateDistance    = 0.000018, -- per metre of travel
}

-- ─────────────────────────────────────────────────────────────────────────
-- VEHICLE DAMAGE
-- Collision detection and environmental degradation.
-- ─────────────────────────────────────────────────────────────────────────
Config.Damage = {
    enabled             = true,
    impactSpeedThresh   = 10.0,     -- m/s velocity drop required to count as a hit
    pollRateMs          = 50,       -- how often velocity is checked
    hitCooldownMs       = 400,      -- min time (ms) between registering hits
    engineDmgPerHit     = 2,        -- GTA engine HP lost per impact
    bodyDmgPerHit       = 4,        -- GTA body HP lost per impact
    waterSinkRate       = 8,        -- engine HP/s drained when submerged
    overRevRate         = 0.5,      -- engine HP/s at sustained redline
    airCoolSpeedMs      = 22.0,     -- m/s — above this, airflow counters over-rev
    gripLossCap         = 0.20,     -- max traction reduction from total damage
    gripLossFloor       = 0.35,     -- minimum grip multiplier (never goes below)
    -- Per–GTA-vehicle-class damage sensitivity multipliers
    classScale          = {
        [8]  = 0.60, -- Motorcycles — lighter, damaged more easily
        [5]  = 0.85, -- SUVs
        [6]  = 0.85, -- Off-road
        [14] = 0.85, -- Industrial / heavy
    },
}

-- ─────────────────────────────────────────────────────────────────────────
-- PERFORMANCE DEGRADATION  (damage → handling penalties)
-- ─────────────────────────────────────────────────────────────────────────
Config.Performance = {
    -- Engine health thresholds (GTA scale 0–1000)
    engineHealthFull    = 1000,
    engineHealthCritical= 100,

    -- At critical engine health, handling suffers by these fractions:
    enginePowerPenalty  = 0.15,     -- drive force reduced to 15 % of stock
    engineTopSpdPenalty = 0.30,     -- top speed reduced to 30 % of stock
    engineRespPenalty   = 0.50,     -- torque response reduced to 50 % of stock

    -- Suspension (body health 0–1000)
    suspStiffnessPenalty    = 0.28, -- spring force reduction at worst damage
    suspDampingPenalty      = 0.25, -- damping reduction at worst damage
    maxCamberShift          = 3.2,  -- degrees of camber misalignment from damage

    -- Steering
    steeringDmgPenalty      = 0.15, -- lock loss at max damage
    steeringSpeedReduction  = 0.48, -- lock at top speed vs. standstill

    -- Brakes
    brakesForcePenalty      = 0.20, -- braking force loss at worst damage
    brakesBiasShift         = 0.14, -- forward bias shift at worst damage

    -- Dynamic geometry (active adjustments per physics state)
    brakeDiveCamber         = 0.015, -- front camber change per m/s² braking
    accelSquatCamber        = 0.010, -- rear camber change per m/s² acceleration
    cornerCamberLoad        = 0.012, -- lateral camber change per m/s² lateral
}

-- ─────────────────────────────────────────────────────────────────────────
-- AERODYNAMICS & SLIPSTREAM
-- ─────────────────────────────────────────────────────────────────────────
Config.Aero = {
    -- Downforce (increases grip at speed)
    downforceEnabled        = true,
    downforceMinSpeedMs     = 12.0, -- m/s (~43 km/h) — aero effect starts
    downforceMaxSpeedMs     = 60.0, -- m/s (~216 km/h) — full downforce reached
    downforceGripBonus      = 0.22, -- maximum grip addition at full speed

    -- Slipstream / drafting (forward push behind a lead vehicle)
    slipstreamEnabled       = true,
    slipstreamMinSpeedMs    = 28.0, -- m/s (~100 km/h) — drafting activates
    slipstreamReach         = 30.0, -- metres — maximum effective draft range
    slipstreamHalfAng       = 38.0, -- degrees half-angle of draft cone
    slipstreamPeakForce     = 0.45, -- velocity push at closest valid range
}

-- ─────────────────────────────────────────────────────────────────────────
-- TELEMETRY HUD
-- ─────────────────────────────────────────────────────────────────────────
Config.Telemetry = {
    enabled         = true,
    activeUpdateMs  = 50,           -- update rate when HUD is visible
    idleUpdateMs    = 500,          -- update rate when HUD is hidden
    toggleKey       = 167,          -- PageUp  — show / hide
    cycleKey        = 168,          -- PageDown — cycle display modes
}
