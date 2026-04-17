-- client/tyre.lua
local function GetGripAtSlip(slipAngleDeg, compound)
  local curve = compound.lat_curve
  local keys = {}
  for k in pairs(curve) do table.insert(keys, k) end
  table.sort(keys)

  for i = 1, #keys - 1 do
    local a0, a1 = keys[i], keys[i+1]
    if slipAngleDeg >= a0 and slipAngleDeg <= a1 then
      local t = (slipAngleDeg - a0) / (a1 - a0)
      local grip = curve[a0] + t * (curve[a1] - curve[a0])
      return compound.min_g + grip * (compound.max_g - compound.min_g)
    end
  end
  return compound.min_g
end

SPZTyre = {
    GetGripAtSlip = GetGripAtSlip
}
