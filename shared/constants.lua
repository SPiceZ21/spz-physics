-- shared/constants.lua
SPZ = SPZ or {}

SPZ.PPClassBrackets = {
  [0] = { name="C", min=0,   max=39  },   -- Class C: Street
  [1] = { name="B", min=40,  max=59  },   -- Class B: Sport
  [2] = { name="A", min=60,  max=79  },   -- Class A: Pro
  [3] = { name="S", min=80,  max=100 },   -- Class S: Elite
}

function GetClassFromPP(pp)
  for tier, bracket in pairs(SPZ.PPClassBrackets) do
    if pp >= bracket.min and pp <= bracket.max then
      return tier
    end
  end
  return 0
end
