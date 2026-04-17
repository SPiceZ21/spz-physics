-- data/enginedata.lua
EngineData = {}

EngineData["EJ20T"] = {
  power_hp  = 280, torque_nm = 350,
  rpm_idle  = 900, rpm_min = 1000, rpm_max = 7800, rpm_limit = 8200,
  power_curve = {
    [1000]=0.20, [2000]=0.40, [3000]=0.65,
    [4000]=0.85, [5000]=1.00, [6000]=0.95,
    [7000]=0.80, [7800]=0.60,
  }
}

EngineData["2JZ-GTE"] = {
  power_hp  = 320, torque_nm = 430,
  rpm_idle  = 750, rpm_min = 800, rpm_max = 7000, rpm_limit = 7400,
  power_curve = {
    [800]=0.15,  [2000]=0.55, [3000]=0.80,
    [4000]=1.00, [5000]=0.98, [6000]=0.85,
    [7000]=0.65,
  }
}

EngineData["SR20DET"] = {
  power_hp  = 250, torque_nm = 300,
  rpm_idle  = 900, rpm_min = 1000, rpm_max = 8500, rpm_limit = 9000,
  power_curve = {
    [1000]=0.18, [2500]=0.50, [3500]=0.75,
    [5000]=1.00, [6500]=0.95, [7500]=0.80,
    [8500]=0.60,
  }
}
