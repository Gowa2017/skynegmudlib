local class  = require("pl.class")
local tablex = require("pl.tablex")

---@class EffectList : Class
---@field effects table<Effect,boolean>
---@field target table
local M      = class()

---comment
---@param target table
---@param effects table[] @effect defs
function M:_init(target, effects)
  self.effects = tablex.copy(effects or {})
  self.target = target
end

function M:size()
  self:validateEffects()
  return tablex.size(self.effects)
end

function M:entries()
  self:validateEffects()
  return tablex.keys(self.effects)
end

function M:hasEffectType(tt) return not self:getByType(tt) end

function M:getByType(tt)
  for effect, _ in pairs(self.effects) do
    if effect.config.type == tt then return effect end
  end

end

function M:emit(event, ...)
  self:validateEffects()
  if event == "effectAdded" or event == "effectRemoved" then return end
  for v, _ in ipairs(self.effects) do
    if v.paused then goto continue end
    if event == "updateTick" and v.config.tickInterval then
      local sinceLastTick = os.time() - v.state.lastTick
      if sinceLastTick < v.config.tickInterval * 1000 then goto continue end
      v.state.lastTick = os.time()
      v.state.ticks = v.state.ticks + 1

    end
    v:emit(event, ...)
    ::continue::
  end

end

function M:add(effect)
  assert(not effect.target, "Cannot add effect, already has a target.")
  for activeEffect, _ in pairs(self.effects) do
    if effect.config.type == activeEffect.config.type then
      if activeEffect.config.maxStacks and activeEffect.state.stacks <
        activeEffect.config.maxStacks then
        activeEffect.state.stacks = math.min(activeEffect.config.maxStacks,
                                             activeEffect.state.stacks + 1)
        activeEffect:emit("effectStackAdded", effect)
      end
      if activeEffect.config.refreshes then
        activeEffect:emit("effectRefreshed", effect)
      end
      if activeEffect.config.unique then return false end
    end

  end
  self.effects[effect] = true
  effect.target = self.target

  effect:emit("effectAdded")
  self.target:emit("effectAdded", effect)
  effect:on("remove", function() self:remove(effect) end)
  return true
end

function M:remove(effect)
  assert(self.effects[effect], "Trying to remove effect that was never adde")
  effect:deactivate()
  self.effects[effect] = nil
  self.target:emit("effectRemoved")
end

function M:clear() self.effects = {} end

function M:validateEffects()
  for effect, _ in pairs(self.effects) do
    if not effect:isCurrent() then self:remove(effect) end
  end
end

function M:evaluateAttribute(attr)
  self:validateEffects()
  local attrName  = attr.name
  local attrValue = attr.base or 0
  for effect, _ in pairs(self.effects) do
    if effect.paused then goto continue end
    attrValue = effect:modifyAttribute(attrName, attrValue)
    ::continue::
  end
  return attrValue
end

function M:evaluateIncomingDamage(damage, currentAmount)
  self:validateEffects()

  tablex.foreach(self.effects, function(_, effect)
    currentAmount = effect:modifyIncomingDamage(damage, currentAmount)
  end)
  return math.max(currentAmount, 0) or 0
end

function M:evaluateOutgoingDamage(damage, currentAmount)
  self:validateEffects()

  tablex.foreachi(self.effects, function(_, effect)
    currentAmount = effect:modifyOutgoingDamage(damage, currentAmount)
  end)

  return math.max(currentAmount, 0) or 0
end

function M:serialize()
  self:validateEffects()
  local serialized = {}
  for effect, _ in pairs(self.effects) do
    if not effect.config.persists then goto continue end
    serialized[#serialized + 1] = effect:serialize()
    ::continue::
  end
  return serialized
end

function M:hydrate(state)
  local effects = self.effects
  self.effects = {}
  for newEffect, _ in pairs(effects) do
    local effect = state.EffectFactory:create(newEffect.id)
    effect:hydrate(state, newEffect)
    self:add(effect)
  end
end

return M
