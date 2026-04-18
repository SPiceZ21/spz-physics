-- client/statebag.lua

-- Helper function to sync physics state to the LocalPlayer statebag
-- This is what spz-hud reads from
function SyncPhysicsStateToBag(state)
    if not state then 
        LocalPlayer.state:set("physics:loaded", false, true)
        return 
    end

    LocalPlayer.state:set("physics:loaded", true, true)
    LocalPlayer.state:set("physics:rpm", state.rpm or 0, true)
    LocalPlayer.state:set("physics:rpm_min", state.profile.engine.rpm_min or 1000, true)
    LocalPlayer.state:set("physics:rpm_max", state.profile.engine.rpm_max or 7000, true)
    LocalPlayer.state:set("physics:gear", state.gear or 0, true)
    LocalPlayer.state:set("physics:gear_count", state.profile.gearbox.gears or 6, true)
    LocalPlayer.state:set("physics:boost", state.boost_bar or 0.0, true)
    
    -- Live assist state (intervening right now)
    LocalPlayer.state:set("physics:tcs_active",   state.tcs_active   or false, true)
    LocalPlayer.state:set("physics:esc_active",   state.esc_active   or false, true)
    LocalPlayer.state:set("physics:abs_active",   state.abs_active   or false, true)
    LocalPlayer.state:set("physics:lc_active",    state.lc_active    or false, true)
    -- Player-toggled enable flags (for speedometer indicators)
    LocalPlayer.state:set("physics:tcs_enabled",  state.tcs_enabled  ~= false, true)
    LocalPlayer.state:set("physics:abs_enabled",  state.abs_enabled  ~= false, true)
    LocalPlayer.state:set("physics:esc_enabled",  state.esc_enabled  ~= false, true)
    
    LocalPlayer.state:set("physics:pp", state.pp or 0.0, true)
    LocalPlayer.state:set("physics:top_speed", state.top_speed or 250, true)
end

function ClearPhysicsStateBag()
    LocalPlayer.state:set("physics:loaded", false, true)
    LocalPlayer.state:set("physics:rpm", 0, true)
    LocalPlayer.state:set("physics:gear", 0, true)
    LocalPlayer.state:set("physics:boost", 0.0, true)
    LocalPlayer.state:set("physics:tcs_active", false, true)
    LocalPlayer.state:set("physics:abs_active", false, true)
end
