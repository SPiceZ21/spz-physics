-- config.lua
Config = {}

-- ── Physics tick ──────────────────────────────────────────────────────────
Config.TickRate         = 0            -- 0 = every frame, set higher to reduce load

-- ── Assists ───────────────────────────────────────────────────────────────
Config.TCSSlipThreshold = 0.25         -- wheel speed delta to trigger TCS
Config.ESCAngleThreshold= 12.0         -- degrees of yaw deviation before ESC fires
Config.LCTargetRPM      = 4000         -- default launch control hold RPM

-- ── Turbo ─────────────────────────────────────────────────────────────────
Config.TurboBoostMultiplier = 0.35     -- how much boost affects torque multiplier

-- ── Gearbox ───────────────────────────────────────────────────────────────
Config.DefaultShiftDelay    = 80       -- ms, used if profile has none

-- ── PP ────────────────────────────────────────────────────────────────────
-- PP bracket thresholds — must match spz-vehicles Config.ClassPP
Config.PPBrackets = {
  [0] = { min=0,  max=39  },   -- C
  [1] = { min=40, max=59  },   -- B
  [2] = { min=60, max=79  },   -- A
  [3] = { min=80, max=100 },   -- S
}

-- ── Debug ─────────────────────────────────────────────────────────────────
Config.Debug              = false
Config.DebugOverlay       = false      -- on-screen physics values during dev
