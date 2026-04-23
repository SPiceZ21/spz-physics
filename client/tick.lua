-- client/tick.lua
-- Main physics loop.  Orchestrates all subsystems in deterministic order:
--
--   Environment  →  Tyre thermals  →  Grip assembly
--   Engine/GB/Turbo  →  Assists  →  Damage/Performance
--   Aero  →  Telemetry  →  Statebag sync
--
-- dt is computed from real elapsed time so physics are frame-rate independent.

local _lastFrameTime = GetGameTimer()
local _lastTorqueMult = 0.0

CreateThread(function()
    while true do
        -- Compute delta-time (seconds) regardless of tick rate
        local now = GetGameTimer()
        local dt  = math.min((now - _lastFrameTime) / 1000.0, 0.2)  -- cap at 200ms
        _lastFrameTime = now

        if PhysicsState and PhysicsState.loaded then
            local vehicle  = PhysicsState.vehicle
            
            -- Defensive: check if vehicle still exists
            if not DoesEntityExist(vehicle) then
                PhysicsState.loaded = false -- Mark as not loaded if entity is gone
                TriggerEvent("SPZ:physics:unloaded")
                goto continue
            end

            local profile  = PhysicsState.profile
            local drivetrain = profile.drivetrain or "FWD"

            -- Inputs
            local throttle  = GetControlValue(0, 71) / 127.0   -- 0–1
            local brake     = GetControlValue(0, 72) / 127.0   -- 0–1
            local speed     = GetEntitySpeed(vehicle)            -- m/s

            -- Kinematics — cache matrix once and reuse across all subsystems
            local vel       = GetEntityVelocity(vehicle)
            local right, fwd = GetEntityMatrix(vehicle)  -- rightVec, forwardVec (first two returns)
            local longAccel = fwd.x * vel.x + fwd.y * vel.y + fwd.z * vel.z
            local latAccel  = math.abs(right.x * vel.x + right.y * vel.y + right.z * vel.z)

            -- ─── 1. Environment ─────────────────────────────────────────────
            -- Removed per request
            -- SPZRoad.Tick(dt)
            -- SPZSurface.Scan(vehicle, SPZRoad.GetWetness())

            -- ─── 2. Tire Thermals ────────────────────────────────────────────
            -- Removed per request

            -- ─── 3. Aerodynamics ─────────────────────────────────────────────
            -- Removed per request
            -- local aeroGripBonus = SPZAero.Tick(vehicle, speed, dt)

            -- ─── 4. Damage & Performance Degradation ─────────────────────────
            -- Removed per request
            -- SPZDamage.Tick(vehicle, PhysicsState.rpm, profile, speed, dt)
            -- SPZPerformance.Apply(vehicle, latAccel, longAccel, speed)

            -- ─── 5. Grip Application Pipeline ────────────────────────────────
            -- Removed per request: This completely stops SetVehicleHandlingFloat spam
            -- local finalGripMult = SPZGrip.Apply(vehicle, profile, aeroGripBonus, damageGripMod)
            PhysicsState.grip_mult = 1.0

            -- ─── 6. Engine (RPM + Power Curve) ──────────────────────────────
            local rawRpm = profile.engine.rpm_min
                         + (GetVehicleCurrentRpm(vehicle)
                           * (profile.engine.rpm_max - profile.engine.rpm_min))
            PhysicsState.rpm  = SPZFlywheel.UpdateRpm(rawRpm, profile.flywheel and profile.flywheel.inertia)

            -- Power output at current RPM
            local powerMult = SPZEngine.GetPowerAtRPM(PhysicsState.rpm, profile.engine.power_curve)

            -- ─── 7. Gearbox ──────────────────────────────────────────────────
            if profile.gearbox.type == "Auto" or profile.gearbox.type == "Sequential" then
                SPZGearbox.AutoShift(vehicle, profile, PhysicsState.rpm)
            end
            PhysicsState.gear    = GetVehicleCurrentGear(vehicle)
            local shiftMult      = SPZGearbox.GetShiftMultiplier()

            -- ─── 8. Turbo / Boost ────────────────────────────────────────────
            local boost, boostMult = SPZTurbo.UpdateBoost(vehicle, profile, PhysicsState.rpm, throttle)
            PhysicsState.boost_bar = boost or 0.0
            boostMult = boostMult or 1.0

            -- ─── 9. Driver Assists ───────────────────────────────────────────
            local tcsActive, tcsMult = SPZAssists.UpdateTCS(vehicle, profile, throttle)
            local lcActive,  lcMult  = SPZAssists.UpdateLC(vehicle, profile, speed, throttle, brake)
            local absActive          = SPZAssists.UpdateABS(vehicle, profile, brake)
            local escActive          = SPZAssists.UpdateESC(vehicle, profile, speed)

            tcsMult = tcsMult or 1.0
            lcMult  = lcMult  or 1.0

            PhysicsState.tcs_active = tcsActive
            PhysicsState.abs_active = absActive
            PhysicsState.esc_active = escActive
            PhysicsState.lc_active  = lcActive

            -- ESC cuts throttle on severe yaw deviation
            local escMult = escActive and 0.45 or 1.0

            -- ─── 10. Final Torque Multiplier ─────────────────────────────────
            -- Nil-safe: a crashed subsystem returns nil → default to 1.0 (no cut)
            local finalTorque = (powerMult  or 1.0)
                              * (boostMult  or 1.0)
                              * (shiftMult  or 1.0)
                              * (tcsMult    or 1.0)
                              * escMult
                              * (lcMult     or 1.0)
                              * (Config.GlobalTorqueMultiplier or 1.0)
                              
            local finalTorqueCapped = math.max(0.0, finalTorque)
            if math.abs(_lastTorqueMult - finalTorqueCapped) > 0.05 then
                SetVehicleEngineTorqueMultiplier(vehicle, finalTorqueCapped)
                _lastTorqueMult = finalTorqueCapped
            end

            -- ─── 11. Tyre Lateral Grip (Compound Slip-Angle Model) ───────────
            -- This stage removed.

            -- ─── 12. Telemetry ───────────────────────────────────────────────
            -- Removed per request
            -- SPZTelemetry.Tick(vehicle, PhysicsState)

            -- ─── 13. Statebag sync (for HUD) ────────────────────────────────
            -- Removed per request
            -- SyncPhysicsStateToBag(PhysicsState)

            -- ─── 14. Havok Engine Debug Overlay ──────────────────────────────
            if Config.DebugOverlay then
                local wSpd0 = GetVehicleWheelSpeed(vehicle, 0)
                local wSpd1 = GetVehicleWheelSpeed(vehicle, 1)
                local wSpd2 = GetVehicleWheelSpeed(vehicle, 2)
                local wSpd3 = GetVehicleWheelSpeed(vehicle, 3)
                
                local sus0 = GetVehicleWheelSuspensionCompression(vehicle, 0)
                local sus1 = GetVehicleWheelSuspensionCompression(vehicle, 1)
                local sus2 = GetVehicleWheelSuspensionCompression(vehicle, 2)
                local sus3 = GetVehicleWheelSuspensionCompression(vehicle, 3)
                
                SetTextFont(0)
                SetTextProportional(1)
                SetTextScale(0.0, 0.35)
                SetTextColour(255, 255, 255, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextDropShadow()
                SetTextOutline()
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(string.format("~y~Havok Physics Debug~w~\nSpeed: %.2f m/s\nRPM: %d\nTorque Mult: %.2f\nWheels Spd: FL:%.2f FR:%.2f RL:%.2f RR:%.2f\nSuspension: FL:%.2f FR:%.2f RL:%.2f RR:%.2f\nAssists: TCS:%s ABS:%s ESC:%s LC:%s", 
                    speed, PhysicsState.rpm, finalTorqueCapped,
                    wSpd0, wSpd1, wSpd2, wSpd3,
                    sus0, sus1, sus2, sus3,
                    tostring(tcsActive), tostring(absActive), tostring(escActive), tostring(lcActive)
                ))
                EndTextCommandDisplayText(0.02, 0.4)
            end

            Wait(Config.TickRate or 0)
        else
            -- No vehicle — run environment tick at low rate to keep state fresh
            local now2 = GetGameTimer()
            local dt2  = math.min((now2 - _lastFrameTime) / 1000.0, 1.0)
            _lastFrameTime = now2
            -- SPZRoad.Tick(dt2) -- Disabled
            Wait(500)
        end
        ::continue::
    end
end)

-- ---------------------------------------------------------------------------
-- Cleanup on vehicle exit (called from main.lua via UnloadVehicleProfile)
-- ---------------------------------------------------------------------------
AddEventHandler("SPZ:physics:unloaded", function()
    local vehicle = PhysicsState and PhysicsState.vehicle
    if vehicle then
        -- SPZGrip.Restore(vehicle)
        -- SPZPerformance.Restore(vehicle)
        -- SPZDamage.Reset(vehicle)
    end
    -- SPZSurface.Reset()
    -- SPZAero.Reset()
    SPZTelemetry.Reset()
end)
