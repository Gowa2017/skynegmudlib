local Room          = require("core.Room")
local EntityFactory = require("core.EntityFactory")

---@class RoomFactory : EntityFactory
local M             = class(EntityFactory)
function M:create(area, entityRef)
  local npc = self:createByType(area, entityRef, Room)
  npc.area = area
  return npc
end

return M
