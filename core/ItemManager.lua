local class    = require("pl.class")
local ItemType = require("core.ItemType")

---@class ItemManager : Class
local M        = class()

function M:_init() self.items = {} end

function M:add(item) self.items[item] = true end

function M:remove(item)
  if item.room then item.room:removeItem(item) end
  if item.carriedBy then item.carriedBy:removeItem(item) end
  if item.type == ItemType.CONTAINER and item.inventory then
    for _, childItem in pairs(item.inventory.items) do self:remove(childItem) end
  end

  item.__pruned = true
  item:removeAllListeners()
  self.items[item] = nil
end

function M:tickAll()
  for uuid, item in ipairs(self.items) do item:emit("updateTick") end

end

return M
