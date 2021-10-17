local ChannelAudience = require("core.ChannelAudience")
---@class AreaAudience : ChannelAudience
local M               = class(ChannelAudience)

---@return Character[]
function M:getBroadcastTargets()
  if not self.sender.room then return {} end
  local area = self.sender.room
  local res  = area:getBroadcastTargets()
  table.remove(res, self.sender)
end

return M
