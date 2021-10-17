local class        = require("pl.class")
local EventManager = require("core.EventManager")
local Effect       = require("core.Effect")
local tablex       = require("pl.tablex")

---@class EffectFactory : Class
---@field effects table<string, table>
local M            = class()
function M:_init() self.effects = {} end

function M:add(id, config, state)
  if self.effects[id] then return end
  local definition   = tablex.update({}, config)
  definition["listeners"] = nil
  local listeners    = config.listeners or {}
  if type(listeners) == "function" then listeners = listeners(state) end
  local eventManager = EventManager()
  for k, v in pairs(listeners) do eventManager:add(k, v) end
  self.effects[id] = { definition   = definition, eventManager = eventManager }
end

function M:has(id) return self.effects.has(id) end

function M:get(id) return self.get(id) end

function M:create(id, config, state)
  config = config or {}
  state = state or {}
  local entry  = self.effects[id]
  assert(entry and entry.definition,
         string.format("No valid entry definition found for effect %d.", id))
  local def    = tablex.update({}, entry.definition)
  def.config = tablex.update(def.config, config)
  def.state = tablex.update(def.state or {}, state)
  local effect = Effect(id, def)
  entry.eventManager:attach(effect)
  return effect
end

return M
