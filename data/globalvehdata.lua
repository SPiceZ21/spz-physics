-- data/globalvehdata.lua
GlobalVehData = {
  engine = {
    power_hp  = 200,
    torque_nm = 250,
    rpm_idle  = 800,
    rpm_min   = 1000,
    rpm_max   = 7000,
    rpm_limit = 7500,
    power_curve = {
      [1000] = 0.20,
      [3000] = 0.75,
      [5000] = 1.00,
      [7000] = 0.70,
    },
  },
  gearbox = {
    type        = "Sequential",
    gears       = 6,
    final_drive = 3.70,
    ratios      = { 3.50, 2.10, 1.45, 1.10, 0.88, 0.70 },
    shift_delay = 100,
    at_shift_point = 0.85,
  },
  turbo = { type = "none" },
  tyre  = "street",
  differential = { type = "Open", lock_pct = 0 },
  flywheel     = { weight_kg = 10, inertia = 0.40 },
  swaybar      = { front_strength = 50, rear_strength = 50, front_bias = 0.50 },
  assists      = { tcs = true, abs = true, esc = true, lc = false },
}
