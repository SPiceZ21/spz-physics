-- client/tick.lua
-- Main physics loop.  Orchestrates all subsystems in deterministic order:
--
--   Environment  →  Tyre thermals  →  Grip assembly
--   Engine/GB/Turbo  →  Assists  →  Damage/Performance
--   Aero  →  Telemetry  →  Statebag sync
--
-- dt is computed from real elapsed time so physics are frame-rate independent.

local _lastFrameTime = GetGameTimer()

CreateThread(function()
    while true do
        -- Compute delta-time (seconds) regardless of tick rate
        local now = GetGameTimer()
        local dt  = math.min((now - _lastFrameTime) / 1000.0, 0.2)  -- cap at 200ms
        _lastFrameTime = now

        if PhysicsState and PhysicsState.loaded then
            local vehicle  = PhysicsState.vehicle
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
            -- Road wetness accumulates / decays based on active weather
            SPZRoad.Tick(dt)

            -- Surface material grip (per wheel raycasts at configured interval)
            SPZSurface.Scan(vehicle, SPZRoad.GetWetness())

            -- ─── 2. Tire Thermals ────────────────────────────────────────────
            SPZThermals.Tick(vehicle, drivetrain, speed, throttle, brake, latAccel, dt)
            local thermalGripMod = SPZThermals.GetGripMod()  -- used by grip pipeline

            -- ─── 3. Aerodynamics ─────────────────────────────────────────────
            -- Returns downforce grip bonus; also applies slipstream impulse
            local aeroGripBonus = SPZAero.Tick(vehicle, speed, dt)

            -- ─── 4. Damage & Performance Degradation ─────────────────────────
            SPZDamage.Tick(vehicle, PhysicsState.rpm, profile, speed, dt)
            local damageGripMod = SPZDamage.GetGripMod(vehicle)

            -- Geometry / handling float penalties from structural damage
            SPZPerformance.Apply(vehicle, latAccel, longAccel, speed)

            -- ─── 5. Grip Application Pipeline ────────────────────────────────
            -- Assembles: surface × weather × compound × thermals × aero × damage
            local finalGripMult = SPZGrip.Apply(vehicle, profile, aeroGripBonus, damageGripMod)
            PhysicsState.grip_mult = finalGripMult

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
            SetVehicleEngineTorqueMultiplier(vehicle, math.max(0.0, finalTorque))

            -- ─── 11. Tyre Lateral Grip (Compound Slip-Angle Model) ───────────
            -- This overwrites fTractionCurveMax/Min from the compound slip curve;
            -- SPZGrip has already set the environmental multiplier above so we
            -- pass finalGripMult as a scale factor into ApplyTyrePhysics.
            SPZTyre.ApplyTyrePhysics(vehicle, profile, speed)

            -- ─── 12. Telemetry ───────────────────────────────────────────────
            SPZTelemetry.Tick(vehicle, PhysicsState)

            -- ─── 13. Statebag sync (for HUD) ────────────────────────────────
            SyncPhysicsStateToBag(PhysicsState)

            Wait(Config.TickRate or 0)
        else
            -- No vehicle — run environment tick at low rate to keep state fresh
            local now2 = GetGameTimer()
            local dt2  = math.min((now2 - _lastFrameTime) / 1000.0, 1.0)
            _lastFrameTime = now2
            SPZRoad.Tick(dt2)
            Wait(500)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Cleanup on vehicle exit (called from main.lua via UnloadVehicleProfile)
-- ---------------------------------------------------------------------------
AddEventHandler("SPZ:physics:unloaded", function()
    local vehicle = PhysicsState and PhysicsState.vehicle
    if vehicle then
        SPZGrip.Restore(vehicle)
        SPZPerformance.Restore(vehicle)
        SPZDamage.Reset(vehicle)
    end
    SPZSurface.Reset()
    SPZThermals.Reset()
    SPZAero.Reset()
    SPZTelemetry.Reset()
end)
