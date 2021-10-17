local class        = require("pl.class")
local EventManager = require "core.EventManager"
---@class BehaviorManager : Class
---@field behaviors table<string,EventManager>
local M            = class()

function M:_init() self.behaviors = {} end

---@param name string
---@return EventManager
function M:get(name) return self.behaviors[name] end

---@param name string
---@return boolean
function M:has(name) return self.behaviors[name] and true end

function M:addListener(behaviorName, event, listener)
  if not self.behaviors[behaviorName] then
    self.behaviors[behaviorName] = EventManager()
  end
  self.behaviors[behaviorName]:add(event, listener)

end

return M
