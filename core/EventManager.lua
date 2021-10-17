local tablex  = require("pl.tablex")
local wrapper = require("core.lib.wrapper")

---@class EventManager : Class
---@field events table<string,function[]> # manage a event's listeners
local M       = class()

function M:_init() self.events = {} end

function M:get(name) return self.events[name] and true end

function M:add(eventName, listener)
  if not self.events[eventName] then self.events[eventName] = {} end
  table.insert(self.events[eventName], listener)
end

function M:attach(emitter, config)
  for event, listeners in pairs(self.events) do
    for _, listener in pairs(listeners) do
      if config then
        emitter:on(event, wrapper.bind(listener, emitter))
      else
        emitter:on(event, wrapper.bind(listener, emitter))
      end
    end
  end
end

function M:detach(emitter, events)
  if type(events) == "string" then
    events = { events }
  elseif not events then
    events = tablex.keys(self.events)
  end
  for _, event in pairs(events) do emitter:removeAllListeners(event) end
end

return M
