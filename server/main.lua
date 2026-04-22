-- server/main.lua

-- ── Damage synchronisation ────────────────────────────────────────────────
-- A client that owns a vehicle and detected a collision fires this event.
-- The server relays it to all other clients so they can update their local
-- copy of the vehicle's health (damage visual sync).
RegisterNetEvent("SPZ:physics:damageSync")
AddEventHandler("SPZ:physics:damageSync", function(netId, engineHP, bodyHP)
    local src = source
    if not netId or engineHP == nil or bodyHP == nil then return end
    -- Broadcast to everyone except the sender (they already applied it locally)
    TriggerClientEvent("SPZ:physics:syncDamage", -1, src, netId, engineHP, bodyHP)
end)

-- ── Vehicle registry exports ──────────────────────────────────────────────

-- Exports for building vehicle registry
exports("GetPP", function(vehicleModel, isTuned, turboOverride)
    if not VehData then return nil end

    local modelName = type(vehicleModel) == "number" and tostring(vehicleModel) or vehicleModel
    local profile = VehData[modelName] or GlobalVehData

    -- Default fallback if somehow still missing
    if not profile then 
        return nil 
    end

    -- Calculate Performance Points
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
