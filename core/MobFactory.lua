local class         = require("pl.class")
local Npc           = require("core.Npc")
local EntityFactory = require("core.EntityFactory")

---@class MobFactory : EntityFactory
local M             = class(EntityFactory)

function M:create(area, entityRef)
  local npc = self:createByType(area, entityRef, Npc)
  npc.area = area
  return npc
end

return M
