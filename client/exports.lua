-- client/exports.lua

-- Exports definitions for physics variables
-- Requires PhysicsState to be correctly updated by tick.lua

exports("GetLoadStatus", function() return PhysicsState ~= nil and PhysicsState.loaded end)

exports("GetVehName", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.name or "Unknown" end)

exports("GetVehicleData", function() return PhysicsState and PhysicsState.profile or nil end)

exports("GetEngine", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.engine or {} end)

exports("GetCurrentRPM", function() return PhysicsState and PhysicsState.rpm or 0 end)

exports("GetMinMaxRPM", function() 
    if not PhysicsState or not PhysicsState.profile then return {} end
    local eng = PhysicsState.profile.engine
    return { min = eng.rpm_min, max = eng.rpm_max, limit = eng.rpm_limit }
end)

exports("GetEnginePTWRatio", function()
    if not PhysicsState or not PhysicsState.profile then return 0 end
    return PhysicsState.profile.engine.power_hp / (PhysicsState.profile.weight or 1)
end)

exports("GetTransmission", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.gearbox or {} end)

exports("GetShiftDelay", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.gearbox.shift_delay or (Config and Config.DefaultShiftDelay) or 80 end)

exports("GetTurbo", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.turbo or { type = "none" } end)

exports("GetTurboPressure", function() return PhysicsState and PhysicsState.boost_bar or 0.0 end)

exports("GetTyre", function()
    if not PhysicsState or not PhysicsState.profile then return {} end
    return TireData and TireData[PhysicsState.profile.tyre] or {}
end)

exports("GetDifferential", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.differential or {} end)

exports("GetFlywheel", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.flywheel or {} end)

exports("GetSwayBarStrength", function()
    if not PhysicsState or not PhysicsState.profile then return { front=0, rear=0 } end
    local sb = PhysicsState.profile.swaybar
    return { front = sb.front_strength, rear = sb.rear_strength }
end)

exports("GetSwayBarFBias", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.swaybar.front_bias or 0.5 end)

exports("GetSuspension", function() return {} end) -- Mock for handling floats snapshot

exports("GetWeight", function() return PhysicsState and PhysicsState.profile and PhysicsState.profile.weight or 0 end)

exports("GetAssists", function()
    return {
        tcs = PhysicsState and PhysicsState.tcs_enabled or false,
        abs = PhysicsState and PhysicsState.abs_enabled or false,
        esc = PhysicsState and PhysicsState.esc_enabled or false,
        lc  = PhysicsState and PhysicsState.lc_enabled or false,
    }
end)

exports("GetPP", function(isTuned, turboOverride)
    if not PhysicsState or not PhysicsState.profile then return nil end
    local ppData = SPZPP.CalculatePP(PhysicsState.profile, isTuned, turboOverride)
    ppData.class = GetClassFromPP(ppData.pp)
    return ppData
end)

exports("GetCTM", function() return PhysicsState and PhysicsState.ctm or 1.0 end)

exports("GetBrakingCapacity", function() return 1.0 end) -- Placeholder
exports("GetBrakingFBias", function() return 0.5 end) -- Placeholder

exports("GetTelemetry", function()
    if not PhysicsState then return {} end
    return {
        power         = PhysicsState.power or 0,
        torque        = PhysicsState.torque or 0,
        boost         = PhysicsState.boost_pct or 0.0,
        boost_bar     = PhysicsState.boost_bar or 0.0,
        air_resistance= PhysicsState.air_resistance or 0.0,
        tcs_active    = PhysicsState.tcs_active or false,
        esc_active    = PhysicsState.esc_active or false,
        abs_active    = PhysicsState.abs_active or false,
        lc_active     = PhysicsState.lc_active or false,
        remaining_nos = PhysicsState.nos or 100.0,
    }
end)

exports("GetEngineSwapData", function()
    if not PhysicsState or not PhysicsState.profile or not PhysicsState.modelName then return {} end
    return EngineSwapData and EngineSwapData[PhysicsState.modelName] or { stock = "", swaps = {} }
end)

-- SETTERS --

-- Note: In a client-side context, 'source' is discarded/irrelevant. If triggered from network, server passes down specific values.
exports("SetAssists", function(sourceOverride, assistsConfig)
    local cfg = assistsConfig or sourceOverride -- if passed directly on client
    if PhysicsState and type(cfg) == "table" then
        if cfg.tcs ~= nil then PhysicsState.tcs_enabled = cfg.tcs end
        if cfg.abs ~= nil then PhysicsState.abs_enabled = cfg.abs end
        if cfg.esc ~= nil then PhysicsState.esc_enabled = cfg.esc end
        if cfg.lc ~= nil then PhysicsState.lc_enabled = cfg.lc end
    end
end)

exports("SetEngineSwap", function(sourceOverride, engineId)
    local id = engineId or sourceOverride
    TriggerEvent("SPZ:physics:engineSwapped", id)
end)

exports("SetTyreCompound", function(sourceOverride, compound)
    local c = compound or sourceOverride
    if PhysicsState and PhysicsState.profile then
        PhysicsState.profile.tyre = c
    end
end)

exports("SetAWDSplit", function(sourceOverride, frontBias)
    local bias = frontBias or sourceOverride
    if PhysicsState and PhysicsState.profile and PhysicsState.profile.differential and type(bias) == "number" then
        PhysicsState.profile.differential.awd_front_bias = bias * 100
    end
end)

exports("SetSwayBar", function(sourceOverride, config)
    local cfg = config or sourceOverride
    if PhysicsState and PhysicsState.profile and PhysicsState.profile.swaybar and type(cfg) == "table" then
        if cfg.front then PhysicsState.profile.swaybar.front_strength = cfg.front end
        if cfg.rear then PhysicsState.profile.swaybar.rear_strength = cfg.rear end
        if cfg.bias then PhysicsState.profile.swaybar.front_bias = cfg.bias end
    end
end)
