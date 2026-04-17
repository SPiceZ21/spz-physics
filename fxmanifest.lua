fx_version 'cerulean'
game 'gta5'

name 'spz-physics'
description 'SPiceZ-Core — Full vehicle physics engine'
version '1.0.0'
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
  'data/tiredata.lua',
  'data/engineswap.lua',
  'data/vehdata.lua',
  'shared/pp.lua',                     -- moved from client/pp.lua to shared
}

client_scripts {
  'client/main.lua',
  'client/engine.lua',
  'client/gearbox.lua',
  'client/turbo.lua',
  'client/tyre.lua',
  'client/differential.lua',
  'client/flywheel.lua',
  'client/swaybar.lua',
  'client/assists.lua',
  'client/engineswap.lua',
  'client/statebag.lua',
  'client/exports.lua',
  'client/tick.lua',                   -- last — starts the main loop
}

server_scripts {
  'server/main.lua',
}

dependencies {
  'spz-lib',
  'spz-core',
  'spz-vehicles',
}
