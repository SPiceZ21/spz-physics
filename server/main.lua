-- server/main.lua

-- Exports for building vehicle registry
exports("GetPP", function(vehicleModel, isTuned, turboOverride)
    if not VehData then return nil end

    local modelName = type(vehicleModel) == "number" and tostring(vehicleModel) or vehicleModel
    local profile = VehData[modelName] or GlobalVehData

    -- Default fallback if somehow still missing
    if not profile then 
        return nil 
    end

    -- Process strings to tables for engine/tyre if necessary
    -- Actually in VehData, tyre is a string (e.g. "sport"). 
    -- pp.lua expects profile to remain as-is since it queries TireData[profile.tyre]
    
    local ppData = SPZPP.CalculatePP(profile, isTuned, turboOverride)
    if ppData then
        ppData.class = GetClassFromPP(ppData.pp)
    end
    return ppData
end)

-- Export for spz-races to force assists
exports("SetAssists", function(source, assistsConfig)
    if source and tonumber(source) then
        TriggerClientEvent("SPZ:physics:forceAssists", source, assistsConfig)
    end
end)
