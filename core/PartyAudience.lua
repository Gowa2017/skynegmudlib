local class           = require("pl.class")
local tablex          = require("pl.tablex")

local ChannelAudience = require("core.ChannelAudience")
---@class PartyAudience : ChannelAudience
local M               = class(ChannelAudience)

function M:getBroadcastTargets()
  if not self.sender.party then return {} end
  return tablex.filter(self.sender.party:getBroadcastTargets(),
                       function(player) return player ~= self.sender end)
end

return M
