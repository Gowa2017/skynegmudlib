local class  = require("pl.class")
local tablex = require("pl.tablex")

---@class Inventory
---@field items table<string,Item>
---@field maxSize number
local M      = class()
function M:_init(init)
  init = tablex.update({
    items = {},
    max   = nil, -- explicit set it ,need we set it
  }, init)
  self.items = init.items
  self.maxSize = init.max
end

function M:setMax(max) self.maxSize = max end

function M:getMax() return self.maxSize end

function M:isFull() return tablex.size(self.items) >= self.maxSize end

function M:addItem(item)
  if self:isFull() then return end
  self.items[item.uuid] = item
end

function M:removeItem(item) self.items[item.uuid] = nil end

function M:serialize()
  local items = {}
  for uuid, item in pairs(self.items) do items[uuid] = item:serialize() end
  return { max   = self.maxSize, items = items }

end

function M:hydrate(state, carriedBy)
  local Item = require("core.Item");
  for uuid, def in pairs(self.items) do
    if Item:class_of(def) then goto continue end
    if not def.entityReference then goto continue end
    local area    = state.AreaManager:getAreaByReference(def.entityReference)
    local newItem = state.ItemFactory:create(area, def.entityReference)
    newItem.uuid = uuid
    newItem.carriedBy = carriedBy
    newItem:initializeInventory(def.inventory)
    newItem:hydrate(state, def)
    self.items[uuid] = newItem
    state.ItemManager:add(newItem)
    ::continue::
  end
end

return M
