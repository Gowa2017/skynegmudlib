local ChannelAudience = require("core.ChannelAudience");
local tablex          = require("pl.tablex")

---@class WorldAudience : ChannelAudience
local M               = class(ChannelAudience)
function M:getBroadcastTargets()
  return tablex.filter(tablex.values(self.state.PlayerManager.players),
                       function(player, _) return player ~= self.sender end)
  -- return this.state.PlayerManager.filter(player => player !== this.sender);
end

return M
