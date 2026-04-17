-- client/engineswap.lua

AddEventHandler("SPZ:physics:engineSwapped", function(engineId)
    if not PhysicsState or not PhysicsState.loaded then return end
    
    local newEngine = EngineData[engineId]
    if not newEngine then
        print(("^1[SPZ-Physics]^0 Engine swap failed: Profile '%s' not found.^0"):format(engineId))
        return
    end

    print(("^2[SPZ-Physics]^0 Swapping engine to %s...^0"):format(engineId))
    
    -- Update the live profile
    PhysicsState.profile.engine = newEngine
    
    -- Recalculate PP with the new engine
    local ppData = SPZPP.CalculatePP(PhysicsState.profile, false)
    PhysicsState.pp = ppData.pp
    PhysicsState.top_speed = ppData.top_speed
    
    -- Reset flywheel to current RPM to avoid physics bounce
    SPZFlywheel.ResetFlywheel(PhysicsState.rpm)
    
    -- Sync update to HUD
    SyncPhysicsStateToBag(PhysicsState)
    
    TriggerEvent("SPZ:physics:engineSwapComplete", PhysicsState.modelName, engineId)
end)
