-- data/globalvehdata.lua
-- Fallback profile for any vehicle not listed in VehData.
-- Represents a generic B-class road car with conservative values.
GlobalVehData = {

    name       = "Unknown Vehicle",
    class      = 1,        -- 0=C 1=B 2=A 3=S
    drivetrain = "FWD",
    weight     = 1500,     -- kg

    engine = {
        power_hp  = 200,
        torque_nm = 250,
        rpm_idle  = 800,
        rpm_min   = 1000,
        rpm_max   = 6800,
        rpm_limit = 7200,
        power_curve = {
            [1000] = 0.18,
            [2000] = 0.42,
            [3000] = 0.70,
            [4500] = 0.92,
            [5500] = 1.00,
            [6500] = 0.88,
            [6800] = 0.70,
        },
    },

    gearbox = {
        type           = "Auto",
        gears          = 6,
        final_drive    = 3.75,
        ratios         = { 3.55, 2.18, 1.52, 1.18, 0.93, 0.76 },
        shift_delay    = 100,
        at_shift_point = 0.85,
    },

    turbo = {
        type            = "none",
        compressor_size = 0,
        boost_start_rpm = 0,
        boost_peak_rpm  = 0,
        max_boost_bar   = 0.0,
        boost_decay     = 0.0,
        lag_factor      = 0.0,
    },

    tyre         = "street",

    differential = {
        type           = "Open",
        lock_pct       = 0,
        awd_front_bias = 50,
    },

    flywheel = {
        weight_kg = 10.0,
        inertia   = 0.42,
    },

    swaybar = {
        front_strength = 50,
        rear_strength  = 50,
        front_bias     = 0.50,
    },

    assists = {
        tcs = false,
        abs = true,
        esc = false,
        lc  = false,
    },
}
