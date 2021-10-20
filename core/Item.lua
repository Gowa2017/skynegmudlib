local class      = require("pl.class")
local sfmt       = string.format
local uuid       = require("core.lib.uuid")
local tablex     = require("pl.tablex")

local GameEntity = require("core.GameEntity")
local ItemType   = require("core.ItemType")
local Logger     = require("core.Logger")
local Inventory  = require("core.Inventory")

---@class Item : GameEntity
---@field area Area
---@field behaviors string[]
---@field defaultItems Item[]
---@field description string
---@field entityReference string #areaId:itemId
---@field id string
---@field maxItems number
---@field isEquipped boolean
---@field keywords string[]
---@field name string
---@field room Room
---@field roomDesc string
---@field script string
---@field uuid string|number
---@field closeable boolean
---@field closed boolean
---@field locked boolean
---@field lockedBy string
---@field carriedBy Character | Item
---@field equippedBy Character
local M          = class(GameEntity)

function M:_init(area, item)
  self:super()
  local validate = { "keywords", "name", "id" }
  for _, prop in ipairs(validate) do
    if not item[prop] then
      error(sfmt("Item in area [%s] missing required property [%s]", area.name,
                 prop))
    end
  end

  self.area = area
  self.metadata = item.metadata or {}
  self.behaviors = tablex.copy(item.behaviors or {})
  self.defaultItems = item.items or {}
  self.description = item.description or "Nothing special."
  self.entityReference = item.entityReference
  self.id = item.id

  self.maxItems = item.maxItems or math.maxinteger
  self:initializeInventory(item.inventory)

  self.isEquipped = item.isEquipped or false
  self.keywords = item.keywords
  self.name = item.name
  self.room = item.room
  self.roomDesc = item.roomDesc or ""
  self.script = item.script

  if type(item.type) == "string" then
    self.type = ItemType[item.type] or item.type
  else
    self.type = item.type or ItemType.OBJECT
  end

  self.uuid = item.uuid or uuid()
  self.closeable = item.closeable or item.closed or item.locked or false
  self.closed = item.closed or false
  self.locked = item.locked or false
  self.lockedBy = item.lockedBy

  self.carriedBy = nil
  self.equippedBy = nil

end

function M:initializeInventory(inventory)
  if inventory then
    self.inventory = Inventory(inventory)
    self.inventory:setMax(self.maxItems)
  else
    self.inventory = nil
  end

end

function M:hasKeyword(keyword) return self.keywords:find(keyword) end

function M:addItem(item)
  self:_setupInventory()
  self.inventory:addItem(item)
  item.carriedBy = self
end

function M:removeItem(item)
  self.inventory:removeItem(item)

  if not self.inventory.size then self.inventory = nil end
  item.carriedBy = nil
end

function M:isInventoryFull()
  self:_setupInventory()
  return self.inventory:isFull()
end

function M:_setupInventory()
  if not self.inventory then
    self.inventory = Inventory({ items = {}, max   = self.maxItems })
  end
end

function M:findCarrier()
  local owner = self.carriedBy

  while owner do
    if not owner.carriedBy then return owner end

    owner = owner.carriedBy
  end
end

function M:open()
  if not self.closed then return end

  self.closed = false
end

function M:close()
  if self.close or not self.closeable then return end
  self.closed = true
end

function M:lock()
  if self.locked or not self.closeable then return end
  self:close()
  self.locked = true
end

function M:unlock()
  if not self.locked then return end
  self.locked = false
end

function M:hydrate(state, serialized)
  serialized = serialized or {}
  if self.__hydrated then
    Logger.warn("Attempted to hydrate already hydrated item.")
    return false
  end

  if serialized.behaviors then
    self.behaviors = tablex.copy(serialized.behaviors)
  end

  self:setupBehaviors(state.ItemBehaviorManager)

  self.description = serialized.description or self.description
  self.keywords = serialized.keywords or self.keywords
  self.name = serialized.name or self.name
  self.roomDesc = serialized.roomDesc or self.roomDesc
  self.metadata = serialized.metadata or self.metadata
  self.closed = serialized["closed"] and serialized.closed or self.closed
  self.locked = serialized["locked"] and serialized.locked or self.locked

  if type(self.area) == "string" then
    self.area = state.AreaManager:getArea(self.area)
  end

  if self.inventory then
    self.inventory:hydrate(state, self)
  else
    for _, defaultItemId in ipairs(self.defaultItems) do
      Logger.verbose("\tDIST: Adding item [%s] to item [%s]", defaultItemId,
                     self.name)
      local newItem = state.ItemFactory:create(self.area, defaultItemId)
      newItem:hydrate(state)
      state.ItemManager:add(newItem)
      self:addItem(newItem)
    end
  end
  self.__hydrated = true
end

function M:serialize()
  local behaviors = tablex.copy(self.behaviors)
  return {
    entityReference = self.entityReference,
    inventory       = self.inventory and self.inventory:serialize(),

    -- metadata is serialized/hydrated to save the state of the item during gameplay
    -- example= the players a food that is poisoned, or a sword that is enchanted
    metadata        = self.metadata,
    description     = self.description,
    keywords        = self.keywords,
    name            = self.name,
    roomDesc        = self.roomDesc,

    closed          = self.closed,
    locked          = self.locked,
    -- behaviors are serialized in case their config was modified during gameplay
    -- and that state needs to persist (charges of a scroll remaining, etc)
    behaviors       = behaviors,
  }
end

return M
