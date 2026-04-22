-- data/vehdata.lua
VehData = {}

VehData["sultan"] = {

  -- ── Identity ──────────────────────────────────────────────────────
  name       = "Karin Sultan",         -- display name
  class      = 1,                      -- 0=C 1=B 2=A 3=S (must match spz-vehicles)
  drivetrain = "AWD",                  -- "FWD" | "RWD" | "AWD"
  weight     = 1380,                   -- kg

  -- ── Engine ────────────────────────────────────────────────────────
  engine = {
    power_hp   = 280,                  -- peak power in HP
    torque_nm  = 350,                  -- peak torque in NM
    rpm_idle   = 900,
    rpm_min    = 1000,
    rpm_max    = 7800,                 -- redline
    rpm_limit  = 8200,                 -- rev limiter (bounces at this)
    power_curve = {                    -- normalized 0.0–1.0 at each RPM band
      [1000] = 0.45,
      [2000] = 0.65,
      [3000] = 0.85,
      [4000] = 0.95,
      [5000] = 1.00,
      [6000] = 0.95,
      [7000] = 0.80,
      [7800] = 0.60,
    },
  },

  -- ── Gearbox ───────────────────────────────────────────────────────
  gearbox = {
    type       = "Sequential",         -- "Sequential" | "Auto" | "Manual"
    gears      = 6,
    final_drive = 3.90,
    ratios     = { 3.45, 2.10, 1.55, 1.18, 0.92, 0.76 },
    shift_delay = 80,                  -- ms between shifts
    at_shift_point = 0.88,             -- Auto mode: shift at 88% RPM
  },

  -- ── Turbo ─────────────────────────────────────────────────────────
  turbo = {
    type            = "single",        -- "none" | "single" | "twin" | "electric"
    compressor_size = 60,              -- mm — larger = more lag, more top boost
    boost_start_rpm = 2800,            -- RPM where boost begins building
    boost_peak_rpm  = 4500,            -- RPM of peak boost
    max_boost_bar   = 1.2,             -- bar of boost at peak
    boost_decay     = 0.15,            -- how fast boost drops on throttle lift (0–1)
    lag_factor      = 0.35,            -- turbo lag (0=instant, 1=very laggy)
  },

  -- ── Tyres ─────────────────────────────────────────────────────────
  tyre = "sport",                      -- references tiredata.lua compound
  -- Valid compounds: "street" | "sport" | "semi_slick" | "slick" | "wet"

  -- ── Differential ──────────────────────────────────────────────────
  differential = {
    type      = "LSD",                 -- "Open" | "LSD" | "Active"
    lock_pct  = 40,                    -- LSD lock percentage (0–100)
    awd_front_bias = 40,               -- AWD front torque % (ignored for FWD/RWD)
  },

  -- ── Flywheel ──────────────────────────────────────────────────────
  flywheel = {
    weight_kg    = 8.5,               -- heavier = slower rev response
    inertia      = 0.35,              -- 0.0 (instant) – 1.0 (heavy diesel)
  },

  -- ── Sway Bar ──────────────────────────────────────────────────────
  swaybar = {
    front_strength = 60,              -- 0–100
    rear_strength  = 40,              -- 0–100
    front_bias     = 0.55,            -- front share of total sway stiffness
  },

  -- ── Assists ───────────────────────────────────────────────────────
  assists = {
    tcs = true,                       -- traction control available
    abs = true,                       -- ABS available
    esc = true,                       -- electronic stability control available
    lc  = true,                       -- launch control available
  },

}
