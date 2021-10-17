local class = require("pl.class")
---@class ChannelManager : Class
---@field channels table<string,Channel>
local M     = class()
function M:_init() self.channels = {} end

function M:get(name) return self.channels[name] end

function M:add(channel)
  self.channels[channel.name] = channel
  if channel.aliases then
    for _, alias in ipairs(channel.aliases) do self.channels[alias] = channel end
  end
end

function M:remove(channel) self.channels[channel.name] = nil end

function M:find(search)
  for name, channel in pairs(self.channels) do
    local s, _ = name:find(search)
    if s == 1 then return channel end
  end
end

return M
