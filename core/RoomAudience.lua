local ChannelAudience = require("core.ChannelAudience")
local tablex          = require("pl.tablex")

---@class RoomAudience : ChannelAudience
local M               = class(ChannelAudience)

function M:getBroadcastTargets()
  return tablex.filter(self.sender.room:getBroadcastTargets(),
                       function(target) return target ~= self.sender end)
end

return M
