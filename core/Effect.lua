local EventEmitter = require("core.EventEmitter")
local tablex       = require("pl.tablex")

---@class Effect : EventEmitter
---@field id string
---@field flags any
---@field config table
---@field startedAt number
---@field paused number
---@field modifiers table
---@field state table
local M            = class(EventEmitter)

function M:_init(id, def)
  self:super()
  self.id = id
  self.flags = def.flags or {}
  self.config = tablex.update({
    autoActivate = true,
    description  = "",
    duration     = math.maxinteger,
    hidden       = false,
    maxStacks    = 0,
    name         = "Unnamed Effect",
    persists     = true,
    refreshes    = false,
    tickInterval = false,
    type         = "undef",
    unique       = true,
  }, def.config)
  self.startedAt = 0
  self.paused = 0
  self.modifiers = tablex.update({
    attributes     = {},
    incomingDamage = function(damage, current) return current end,
    outgoingDamage = function(damage, current) return current end,
  }, def.modifiers)
  self.state = tablex.update({}, def.state)
  self.state.stacks = self.config.maxStacks and 1
  if self.config.tickInterval and not self.state.tickInterval then
    self.state.lastTick = math.mininteger
    self.state.ticks = 0
  end
  if self.config.autoActivate then self:on("effectAdded", self.activate) end
end

function M:name() return self.config.name end

function M:description() return self.config.description end

function M:duration() return self.config.duration end

function M:setDuration(dur) self.config.duration = dur end

function M:elapsed()
  return self.startedAt and (self.paused or os.time() - self.startedAt) or nil
end

function M:remaining() return self.config.duration - self.elapsed end

function M:isCurrent() return self.elapsed < self.config.duration end

function M:activate()
  assert(self.target, "Cannot activate an effect without a target")
  if self.active then return end

  self.startedAt = os.time() - self.elapsed
  self:emit("effectActivated")
  self.active = true
end

function M:deactivate()
  if not self.active then return end

  self:emit("effectDeactivated")
  self.active = false
end

function M:remove() self:emit("remove") end

function M:pause() self.paused = self.elapsed end

function M:resume()
  self.startedAt = os.time() - self.paused
  self.paused = nil
end

function M:modifyAttribute(attrName, currentValue)
  local modifier = function() end

  --- modifier need to get the state of effect
  if type(self.modifiers.attributes) == "function" then
    modifier = function(current)
      return self.modifiers.attributes(self, attrName, current)
    end

  else
    if self.modifiers.attributes[attrName] then
      modifier = self.modifiers.attributes[attrName]
    end
    return modifier(self, currentValue)
  end
end

function M:modifyIncomingDamage(damage, currentAmount)
  local modifier = self.modifiers.incomingDamage
  return modifier(self, damage, currentAmount)
end

function M:modifyOutgoingDamage(damage, currentAmount)
  local modifier = self.modifiers.outgoingDamage
  return modifier(self, damage, currentAmount)
end

function M:serialize()
  local config = tablex.update({}, self.config)
  config.duration = config.duration == math.maxinteger and "inf" or
                      config.duration

  local state  = tablex.update({}, self.state)
  if state.lastTick and type(state.lastTick) == "number" then
    state.lastTick = os.time() - state.lastTick
  end
  return {
    elapsed   = self.elapsed,
    id        = self.id,
    remaining = self.remaining,
    skill     = self.skill and self.skill.id,
    config    = config,
    state     = state,
  }
end

function M:hydrate(state, data)
  data.config.duration = data.config.duration == "inf" and math.maxinteger or
                           data.config.duration
  self.config = data.config
  if type(data.elapsed) == "number" then
    self.startedAt = os.time() - data.elapsed
  end

  if type(data.state.lastTick) == "number" then
    data.state.lastTick = os.time() - data.state.lastTick
  end

  self.state = data.state

  if data.skill then
    self.skill = state.SkillManager:get(data.skill) or
                   state.SpellManager:get(data.skill)
  end
end

return M
