-- config.lua
_G.Config = {}
local Config = _G.Config
SPZ = exports["spz-lib"]:GetCoreObject()

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

-- ── Telemetry ─────────────────────────────────────────────────────────────
Config.Telemetry = {
  enabled        = true,
  activeUpdateMs = 50,      -- update rate when HUD is visible
  idleUpdateMs   = 1000,    -- update rate when HUD is hidden (still triggers local event)
  toggleKey      = 10,      -- PAGE UP
  cycleKey       = 11,      -- PAGE DOWN
}

-- ── Thermals ──────────────────────────────────────────────────────────────
Config.Thermals = {
  enabled             = true,
  ambientBaseTemp     = 25.0,   -- Celsius
  slipHeatRate        = 1.8,    -- how fast sliding heats tires
  brakeHeatRate       = 0.4,    -- heating from braking
  cornerHeatRate      = 0.6,    -- heating from lateral load
  rollHeatRate        = 0.05,   -- base friction heating
  airflowCoolPerMs    = 0.02,   -- cooling from speed
  radiationCool       = 0.1,    -- base stationary cooling
  maxCapTemp          = 180.0,  -- hard limit
  coldGripStartTemp   = 45.0,   -- full grip below this is reduced
  optimalLow          = 70.0,   -- sweet spot start
  optimalHigh         = 95.0,   -- sweet spot end
  hotGripStartTemp    = 115.0,  -- grip starts falling off here
  blowoutThreshold    = 155.0,  -- tire fails
  maxColdGripLoss     = 0.25,   -- max penalty for cold tires
  maxHotGripLoss      = 0.40,   -- max penalty for overheated tires
  wearRateSlip        = 0.0001,
  wearRateBrake       = 0.00005,
  wearRateDistance    = 0.000001,
}


