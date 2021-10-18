local class         = require("pl.class")
local Room          = require("core.Room")
local EntityFactory = require("core.EntityFactory")

---@class RoomFactory : EntityFactory
local M             = class(EntityFactory)
function M:create(area, entityRef)
  local room = self:createByType(area, entityRef, Room)
  room.area = area
  return room
end

return M
