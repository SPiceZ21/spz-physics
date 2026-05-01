fx_version 'cerulean'
game 'gta5'

name 'spz-physics'
description 'SPiceZ-Core — Full vehicle physics engine'
version '1.5.1'
author 'SPiceZ-Core'

shared_scripts {
  '@spz-lib/shared/main.lua',
  '@spz-lib/shared/logger.lua',
  '@spz-lib/shared/math.lua',
  'shared/events.lua',
  'shared/constants.lua',
  'config.lua',
  'data/globalvehdata.lua',
  'data/enginedata.lua',
  'data/engineswap.lua',
  'data/vehdata.lua',
  'shared/pp.lua',
}

client_scripts {
  -- Core state initialisation (must be first)
  'client/main.lua',
  'client/helpers.lua',   -- Polyfills (GetEntityRightVector, etc.)
  'client/statebag.lua',

  -- Environment systems (no vehicle dependency — load early)
  'client/surface.lua',
  'client/road.lua',

  -- Per-vehicle physics modules
  'client/grip.lua',
  'client/tyre.lua',
  'client/thermals.lua',
  'client/damage.lua',
  'client/performance.lua',
  'client/aero.lua',

  -- Drivetrain simulation
  'client/engine.lua',
  'client/gearbox.lua',
  'client/turbo.lua',
  'client/flywheel.lua',

  -- Handling geometry
  'client/differential.lua',
  'client/swaybar.lua',

  -- Driver aids
  'client/assists.lua',

  -- Event handlers
  'client/engineswap.lua',

  -- HUD / telemetry
  'client/telemetry.lua',

  -- Public API surface
  'client/exports.lua',

  -- Main loop (must be last — depends on everything above)
  'client/tick.lua',
}

server_scripts {
  'server/main.lua',
}

dependencies {
  'spz-lib',
  'spz-core',
  'spz-vehicles',
}
