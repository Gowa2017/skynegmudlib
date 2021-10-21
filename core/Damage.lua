local class = require("pl.class")
local sfmt  = string.format
---@class Damage :Class
---@field attacker Character
---@field attribute string
---@field amount number
---@field source string
---@field metadata table
local M     = class()

---@param attribute string
---@param amount number
---@param attacker? Character
---@param source? any
---@param metadata? table
function M:_init(attribute, amount, attacker, source, metadata)
  metadata = metadata or {}

  assert(type(amount) == "number",
         sfmt("Damage amount must be a finite Number, got %q.", amount))

  assert(type(attribute) == "string", "Damage attribute name must be a string")

  self.attacker = attacker
  self.attribute = attribute
  self.amount = amount
  self.source = source
  self.metadata = metadata
end

---@param target Character
---@return number
function M:evaluate(target)
  local amount = self.amount
  if self.attacker then
    amount = self.attacker:evaluateOutgoingDamage(self, amount)
  end

  return target:evaluateIncomingDamage(self, amount)
end

---@param target Character
function M:commit(target)
  local finalAmount = self:evaluate(target)
  target:lowerAttribute(self.attribute, finalAmount)
  if self.attacker then self.attacker:emit("hit", self, target, finalAmount) end
  target:emit("damaged", self, finalAmount)
end

return M
