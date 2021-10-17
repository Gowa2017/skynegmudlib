local Damage = require("core.Damage")
---@class Heal :Damage
local M      = class(Damage)

function M:commit(target)
  local finalAmount = self:evaluate(target)
  target:raiseAttribute(self.attribute, finalAmount)
  if self.attacker then self.attacker:emit("heal", self, target, finalAmount) end
  target:emit("healed", self, finalAmount)
end

return M
