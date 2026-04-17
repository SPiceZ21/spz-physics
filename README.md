<div align="center">

<img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%"/>

<br/>

# spz-physics

### Advanced Vehicle Physics Engine

*Full-fidelity vehicle physics overhaul for SPiceZ-Core. Replaces GTA V default handling with a custom simulation layer including real-time RPM, gearbox logic, turbo pressure, and active driver assists.*

<br/>

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-orange.svg?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=flat-square)](https://fivem.net)
[![Status](https://img.shields.io/badge/Status-Beta-yellow?style=flat-square)]()

</div>

---

## Overview

`spz-physics` replaces GTA V's simplified vehicle simulation with a per-frame physics engine. It runs custom logic on top of the base handling, modulating torque, grip, and RPM to create a "Gran Turismo" style driving feel.

**Key Features:**
- **Custom RPM Engine**: Maps 0-1 native RPM to real numerical ranges with power curves and rev limiters.
- **Gearbox Simulation**: Supports Sequential, Automatic, and Manual modes with shift delays and RPM matching.
- **Turbo Simulation**: Dynamic boost pressure building, decay, and turbo lag based on compressor size.
- **Tyre Model**: Lateral G slip-angle model that adjusts traction live based on driving intensity and compound.
- **Active Assists**: Built-in Traction Control (TCS), Anti-lock Brakes (ABS), and Launch Control (LC).
- **PP Rating System**: Performance Point calculation used for vehicle class gating (C/B/A/S).
- **Telemetry Layer**: Pushes live data to statebags for HUD consumption and data logging.

---

## Subsystems

| System | Role | Integration |
|---|---|---|
| **Engine** | RPM mapping & Power Curve | `SetVehicleEngineTorqueMultiplier` |
| **Gearbox** | Shifting & Final Drive | `SetVehicleCurrentRpm` |
| **Turbo** | Boost Pressure & Lag | Torque Bonus |
| **Tyre** | Grip breakaway & Lateral G | `fTractionCurveMax` |
| **Differential** | LSD & AWD Torque Split | `fDriveBiasFront` |
| **Sway Bar** | Body Roll Resistance | `fAntiRollBarForce` |
| **Assists** | TCS / ABS / ESC / LC | Torque/Brake Cuts |

---

## Dependencies

| Resource | Type | Role |
|---|---|---|
| `spz-lib` | Required | Logger, math utilities |
| `spz-core` | Required | Event bus |
| `spz-vehicles` | Required | Reads vehicle registry for initial PP/Class sync |

```cfg
ensure spz-lib
ensure spz-core
ensure spz-vehicles
ensure spz-physics
```

---

## Telemetry (Statebags)

Live physics values are pushed to `LocalPlayer.state` every frame. `spz-hud` consumes these for the speedometer.

| Key | Type | Description |
|---|---|---|
| `physics:loaded` | bool | Whether a physics profile is active |
| `physics:rpm` | number | Real-time engine RPM |
| `physics:rpm_max` | number | Redline RPM |
| `physics:gear` | number | Current gear (0=R, 1-N=Gears) |
| `physics:boost` | number | Turbo pressure percentage (0.0-1.0) |
| `physics:tcs_active`| bool | True if Traction Control is cutting power |
| `physics:abs_active`| bool | True if ABS is pulsing brakes |
| `physics:pp` | number | Calculated Performance Points |

---

## Exports Reference

### Server
```lua
-- Fetch PP for a vehicle model (used by spz-vehicles)
local ppData = exports["spz-physics"]:GetPP(modelName, isTuned)

-- Force assist states for a player (used by spz-races)
exports["spz-physics"]:SetAssists(source, { tcs = true, abs = true })
```

### Client
```lua
-- Get live engine data
local rpm = exports["spz-physics"]:GetCurrentRPM()

-- Set engine swap live
exports["spz-physics"]:SetEngineSwap("2JZ-GTE")
```

---

## Configuration

```lua
-- config.lua
Config.TickRate         = 0       -- 0 = every frame (required for smooth physics)
Config.TCSSlipThreshold = 0.25    -- speed delta before TCS triggers
Config.TurboMultiplier  = 0.35    -- peak torque bonus from max boost
Config.PPBrackets       = { ... } -- C/B/A/S point thresholds
```

---

<div align="center">

*Part of the [SPiceZ-Core](https://github.com/SPiceZ21) ecosystem*

**[Docs](https://github.com/SPiceZ21/spz-docs) · [Discord](https://discord.gg/) · [Issues](https://github.com/SPiceZ21/spz-physics/issues)**

</div>
