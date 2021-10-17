---@class EventEmitter : Class
---@field events table<string, table<function,boolean>> # every event hava a listener table, every listener will tagged is once or not
local M      = class()

local tablex = require "pl.tablex"
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

function M:removeAllListeners(event) tablex.clear(self.events[event]) end

function M:setMaxListeners(n) self.n = n end

function M:listeners(event) return tablex.keys(self.events[event]) end

function M:emit(event, ...)
  tablex.foreach(self.events[event] or {}, function(once, listener, ...)
    local ok, err = xpcall(listener, debug.traceback, ...)
    if not ok then Logger.error(err) end
    if once then self.events[event][listener] = nil end
  end, ...)
end

return M
