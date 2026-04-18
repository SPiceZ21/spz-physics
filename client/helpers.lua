-- client/helpers.lua
-- Polyfills for FiveM natives that don't exist natively.

--- GetEntityRightVector
-- FiveM only provides GetEntityForwardVector — there is no built-in
-- right-vector native.  We derive it via a 2-D cross product with the
-- world-up axis (0, 0, 1):
--
--   right = forward × up  →  (fwd.y, -fwd.x, 0)
--
-- This is accurate for ground vehicles where roll is negligible.
---@param entity number
---@return vector3
function GetEntityRightVector(entity)
    local fwd = GetEntityForwardVector(entity)
    return vector3(fwd.y, -fwd.x, 0.0)
end
