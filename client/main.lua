-- client/main.lua

PhysicsState = nil

local function LoadVehicleProfile(vehicle)
    local modelHash = GetEntityModel(vehicle)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(modelHash))
    
    -- Try to find a named profile
    local profile = VehData[modelName] or GlobalVehData
    
    -- Initialize live state object
    PhysicsState = {
        vehicle = vehicle,
        modelName = modelName,
        profile = profile,
        loaded = true,
        rpm = 0,
        gear = 1,
        boost_bar = 0.0,
        tcs_enabled = profile.assists.tcs,
        abs_enabled = profile.assists.abs,
        esc_enabled = profile.assists.esc,
        lc_enabled = profile.assists.lc,
        tcs_active = false,
        abs_active = false,
        esc_active = false,
        lc_active = false,
    }

    -- Calculate baseline PP for this vehicle
    local ppData = SPZPP.CalculatePP(profile, false)
    PhysicsState.pp = ppData.pp
    PhysicsState.top_speed = ppData.top_speed

    -- Reset all subsystems for the new vehicle
    SPZThermals.Reset()
    SPZDamage.Reset(vehicle)
    SPZAero.Reset()
    
    -- Notify system
    TriggerEvent("SPZ:physics:loaded", modelName, profile)
    SyncPhysicsStateToBag(PhysicsState)
    
    return true
end

local function UnloadVehicleProfile()
    PhysicsState = nil
    SyncPhysicsStateToBag(nil)
    TriggerEvent("SPZ:physics:unloaded")
end

-- Monitor vehicle entry/exit
CreateThread(function()
    local inVehicle = false
    
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            if not inVehicle then
                inVehicle = true
                LoadVehicleProfile(vehicle)
            end
        else
            if inVehicle then
                inVehicle = false
                UnloadVehicleProfile()
            end
        end
        
        Wait(500)
    end
end)
