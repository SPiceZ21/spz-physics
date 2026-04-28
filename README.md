<div align="center">

<img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%"/>

<br/>

# spz-physics
> Full vehicle physics engine · `v1.5.0`

## Scripts

### Shared / Config

| Side   | File                           | Purpose                                      |
| ------ | ------------------------------ | -------------------------------------------- |
| Shared | `@spz-lib/shared/main.lua`     | spz-lib shared utility import                |
| Shared | `logger.lua`                   | Physics-scoped logger setup                  |
| Shared | `math.lua`                     | Physics math helpers                         |
| Shared | `shared/events.lua`            | Shared event name constants                  |
| Shared | `shared/constants.lua`         | Physics constants (gravity, friction, etc.)  |
| Shared | `config.lua`                   | Resource configuration and tuning            |
| Shared | `data/globalvehdata.lua`       | Global vehicle physics data table            |
| Shared | `data/enginedata.lua`          | Engine specification data                    |
| Shared | `data/engineswap.lua`          | Engine swap compatibility data               |
| Shared | `data/vehdata.lua`             | Per-vehicle physics overrides                |
| Shared | `shared/pp.lua`                | Post-processing physics utilities            |

### Client — Core

| Side   | File               | Purpose                                        |
| ------ | ------------------ | ---------------------------------------------- |
| Client | `main.lua`         | Entry point, tick registration                 |
| Client | `helpers.lua`      | Shared client helper functions                 |
| Client | `statebag.lua`     | State bag reads and writes                     |

### Client — Surface & Road

| Side   | File          | Purpose                              |
| ------ | ------------- | ------------------------------------ |
| Client | `surface.lua` | Surface material detection           |
| Client | `road.lua`    | Road grip and surface mapping        |

### Client — Handling

| Side   | File              | Purpose                              |
| ------ | ----------------- | ------------------------------------ |
| Client | `grip.lua`        | Tyre grip simulation                 |
| Client | `damage.lua`      | Collision and damage effects         |
| Client | `performance.lua` | Vehicle performance modifiers        |
| Client | `aero.lua`        | Aerodynamic downforce simulation     |

### Client — Drivetrain

| Side   | File           | Purpose                              |
| ------ | -------------- | ------------------------------------ |
| Client | `engine.lua`   | Engine power and response            |
| Client | `gearbox.lua`  | Gear shift logic and ratios          |
| Client | `turbo.lua`    | Turbo boost and lag simulation       |
| Client | `flywheel.lua` | Flywheel inertia effects             |

### Client — Chassis

| Side   | File             | Purpose                              |
| ------ | ---------------- | ------------------------------------ |
| Client | `differential.lua` | Differential torque split          |
| Client | `swaybar.lua`    | Anti-roll bar stiffness simulation   |

### Client — Systems

| Side   | File            | Purpose                                        |
| ------ | --------------- | ---------------------------------------------- |
| Client | `assists.lua`   | Driver assist systems (ABS, TC, etc.)          |
| Client | `engineswap.lua`| Apply engine swap data to vehicle              |
| Client | `telemetry.lua` | Telemetry data broadcast for speedometer       |
| Client | `exports.lua`   | Client-side export definitions                 |
| Client | `tick.lua`      | Main per-frame physics update loop             |

### Server

| Side   | File              | Purpose                                        |
| ------ | ----------------- | ---------------------------------------------- |
| Server | `server/main.lua` | Server authority, state sync, exports          |

## Dependencies
- spz-lib
- spz-core
- spz-vehicles

## CI
Built and released via `.github/workflows/release.yml` on push to `main`.
