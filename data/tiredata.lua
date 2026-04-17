-- data/tiredata.lua
TireData = {}

TireData["street"] = {
  name      = "Street",
  max_g     = 1.10,            -- peak lateral G before breakaway
  min_g     = 0.55,            -- minimum G at full slip
  lat_curve = {                -- normalized grip at slip angle (degrees)
    [0]  = 0.00,
    [3]  = 0.75,
    [6]  = 1.00,               -- peak at 6 degrees slip
    [10] = 0.85,
    [15] = 0.65,
    [25] = 0.55,
  },
  heat_buildup  = 0.12,        -- heat generated per second at peak slip
  heat_falloff  = 0.05,        -- heat lost per second not sliding
}

TireData["sport"] = {
  name      = "Sport",
  max_g     = 1.35,
  min_g     = 0.70,
  lat_curve = {
    [0]=0.00, [4]=0.80, [7]=1.00, [12]=0.90, [18]=0.72, [28]=0.62,
  },
  heat_buildup = 0.08,
  heat_falloff = 0.06,
}

TireData["semi_slick"] = {
  name      = "Semi-Slick",
  max_g     = 1.65,
  min_g     = 0.80,
  lat_curve = {
    [0]=0.00, [5]=0.85, [9]=1.00, [14]=0.95, [20]=0.80, [30]=0.72,
  },
  heat_buildup = 0.06,
  heat_falloff = 0.07,
}

TireData["slick"] = {
  name      = "Slick",
  max_g     = 2.00,
  min_g     = 0.90,
  lat_curve = {
    [0]=0.00, [6]=0.90, [10]=1.00, [16]=0.98, [22]=0.85, [32]=0.78,
  },
  heat_buildup = 0.05,
  heat_falloff = 0.08,
}

TireData["wet"] = {
  name      = "Wet",
  max_g     = 1.20,
  min_g     = 0.60,
  lat_curve = {
    [0]=0.00, [3]=0.80, [6]=1.00, [10]=0.80, [15]=0.60, [25]=0.50,
  },
  heat_buildup = 0.04,
  heat_falloff = 0.09,
}
