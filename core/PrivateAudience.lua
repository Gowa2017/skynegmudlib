local stringx         = require("pl.stringx")

local ChannelAudience = require("core.ChannelAudience");

---@class PrivateAudience  : ChannelAudience
local M               = class(ChannelAudience)
function M:getBroadcastTargets()
  local targetPlayerName = stringx.split(" ")[1]
  local targetPlayer     = self.state.PlayerManager:getPlayer(targetPlayerName)
  if targetPlayer then return { targetPlayer } end
  return {};
end

function M:alterMessage(message)
  -- Strips target name from message
  return table.concat(stringx.split(message, " "), " ", 2)
end

return M
