-- client/tick.lua

CreateThread(function()
    while true do
        if PhysicsState and PhysicsState.loaded then
            local vehicle = PhysicsState.vehicle
            local profile = PhysicsState.profile
            local throttle = GetControlValue(0, 71) / 127.0 -- 0.0 to 1.0 (accelerate)
            local brake = GetControlValue(0, 72) / 127.0 -- 0.0 to 1.0 (brake)
            local speed = GetEntitySpeed(vehicle)
            
            -- 1. Engine & Gearbox
            local currentRpmNormalized = GetVehicleCurrentRpm(vehicle)
            local realRpmTarget = profile.engine.rpm_min + (currentRpmNormalized * (profile.engine.rpm_max - profile.engine.rpm_min))
            
            -- Apply flywheel inertia
            PhysicsState.rpm = SPZFlywheel.UpdateRpm(realRpmTarget, profile.flywheel and profile.flywheel.inertia)
            
            -- Transmission
            if profile.gearbox.type == "Auto" or profile.gearbox.type == "Sequential" then
                SPZGearbox.AutoShift(vehicle, profile, PhysicsState.rpm)
            end
            PhysicsState.gear = GetVehicleCurrentGear(vehicle)
            
            -- 2. Turbo Simulation
            local boost, boostMult = SPZTurbo.UpdateBoost(vehicle, profile, PhysicsState.rpm, throttle)
            boostMult = boostMult or 1.0
            PhysicsState.boost_bar = boost or 0.0

            -- 3. Assists Intervention
            local tcsActive, tcsMult = SPZAssists.UpdateTCS(vehicle, profile, throttle)
            tcsMult = tcsMult or 1.0
            PhysicsState.tcs_active = tcsActive
            PhysicsState.abs_active = SPZAssists.UpdateABS(vehicle, profile, brake)
            PhysicsState.lc_active  = SPZAssists.UpdateLC(vehicle, profile, speed, throttle, brake)
            
            -- 4. Tyre Model
            SPZTyre.ApplyTyrePhysics(vehicle, profile, speed)
            
            -- 5. Final torque modulation (Power Curve + Modifiers)
            local powerCurveMult = SPZEngine.GetPowerAtRPM(PhysicsState.rpm, profile.engine.power_curve)
            local shiftMult = SPZGearbox.GetShiftMultiplier()
            
            local finalTorqueMult = powerCurveMult * boostMult * tcsMult * shiftMult
            SetVehicleEngineTorqueMultiplier(vehicle, finalTorqueMult)
            
            -- 6. HUD Sync (Statebag)
            SyncPhysicsStateToBag(PhysicsState)
            
            Wait(Config.TickRate or 0)
        else
            Wait(500)
        end
    end
end)
