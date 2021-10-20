local class  = require("pl.class")
---@class EventEmitter : Class
---@field events table<string, table<function,boolean>> # every event hava a listener table, every listener will tagged is once or not
local M      = class()

local Logger = require "core.Logger"
function M:_init()
  self.events = {}
  self.n = 100
end

function M:add(event, listener, once)
  once = once or false
  if not self.events[event] then self.events[event] = {} end
  self.events[event][listener] = once

end

function M:once(event, listener) self:add(event, listener, true) end

function M:on(event, listener) self:add(event, listener, false) end

function M:removeListener(event, listener) self.events[event][listener] = nil end

function M:removeAllListeners(event)
  if not self.events[event] then return end
  for listener, _ in pairs(self.events[event]) do
    self.events[event][listener] = nil
  end
end

function M:setMaxListeners(n) self.n = n end

function M:listeners(event)
  if not self.events[event] then return {} end
  local res = {}
  for listener, _ in pairs(self.events[event]) do res[#res + 1] = listener end
  return res
end

function M:emit(event, ...)
  if not self.events[event] then
    self.events[event] = {}
    return
  end
  for _, listener in ipairs(self:listeners(event)) do
    local ok, err = xpcall(listener, debug.traceback, ...)
    if not ok then Logger.error("Event callback error:%q", err) end
    if self.events[event][listener] then self.events[event][listener] = nil end
  end
end

return M
