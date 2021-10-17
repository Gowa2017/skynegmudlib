---@class ChannelAudience :Class
local M = class()

function M:configure(options)
  self.state = options.state
  self.sender = options.sender
  self.message = options.message
end

---@return Player[]
function M:getBroadcastTargets()
  return self.state.PlayerManager:getPlayersAsArray()
end

function M:alterMessage(message) return message end

return M
