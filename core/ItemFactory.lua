local class         = require("pl.class")
local EntityFactory = require("core.EntityFactory")
local Item          = require("core.Item")

---@class ItemFactory : EntityFactory
local M             = class(EntityFactory)

---@param area Area
---@param entityRef string
---@return Item
function M:create(area, entityRef)
  local item = self:createByType(area, entityRef, Item)
  item.area = area
  return item
end

return M
