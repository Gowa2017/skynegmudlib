local Metadatable  = require("core.Metadatable")
local EventEmitter = require("core.EventEmitter")
local Inventory    = require("core.Inventory")
local Attributes   = require("core.Attributes")
local EffectList   = require("core.EffectList")
local Logger       = require("core.Logger")
local Config       = require("core.Config")
local pretty       = require("pl.pretty")

local tablex       = require("pl.tablex")
local sfmt         = string.format
---@class Character : EventEmitter, Metadatable
---@field name string
---@field inventory Inventory
---@field equipment table<string,Item>
---@field combatants table<Character,boolean>
---@field combatData table
---@field level number
---@field room Room
---@field attributes Attributes
---@field effects EffectList
---@field followers table<Character, boolean>
---@field metadata table
---@field party Party
local M            = Metadatable(EventEmitter)
function M:_init(data)
  assert(data, "Character: need init table")
  self:super()
  self.name = data.name
  self.inventory = Inventory(data.inventory or {})
  self.equipment = data.equipment or {}
  self.combatants = {} -- set
  self.combatData = {}
  self.level = data.level or 1
  self.room = data.room or nil
  self.attributes = data.attributes or Attributes()
  self.followers = {} -- set
  self.following = nil
  self.party = nil
  self.effects = EffectList(self, data.effects)
  self.metadata = data.metadata or {}
end

function M:emit(event, ...)
  Logger.debug("Character event: %s", event)
  EventEmitter.emit(self, event, ...)
  self.effects:emit(event, ...)
end

function M:hasAttribute(attr) return self.attributes:has(attr) and true end

function M:getMaxAttribute(attr)
  assert(self.attributes:has(attr),
         sfmt("Character has not [%s] attribute", attr))
  local attribute      = self.attributes:get(attr)
  local currentVal     = self.effects:evaluateAttribute(attribute)
  local formula        = attribute.formula
  if not attribute.formula then return currentVal end
  local requiredValues = tablex.imap(function(reqAttr)
    return self:getMaxAttribute(reqAttr)
  end, formula.requires)
  return formula.evaluate(attribute, self, currentVal,
                          table.unpack(requiredValues))
end

function M:addAttribute(attribute) self.attributes:add(attribute) end

---获取某一属性经过计算后的数值
---@param attr string
---@return number
function M:getAttribute(attr)
  assert(self:hasAttribute(attr),
         sfmt("Character does not have attribute %s", attr))
  return self:getMaxAttribute(attr) + self.attributes:get(attr).delta
end

function M:getBaseAttribute(attr)
  local attrbiute = self.attributes:get(attr)
  return attrbiute and attrbiute.base
end

function M:setAttributeToMax(attr)
  assert(self:hasAttribute(attr), sfmt("Invalid attribute %s", attr))
  self.attributes:get(attr):setDelta(0)
  self:emit("attributeUpdate", attr, self:getAttribute(attr))
end

function M:raiseAttribute(attr, amount)
  assert(self:hasAttribute(attr), sfmt("Invalid attribute %s", attr))
  self.attributes:get(attr):raise(amount)
  self:emit("attributeUpdate", attr, self:getAttribute(attr))
end

function M:lowerAttribute(attr, amount)
  assert(self:hasAttribute(attr), sfmt("Invalid attribute %s", attr))
  self.attributes:get(attr):lower(amount)
  self:emit("attributeUpdate", attr, self:getAttribute(attr))
end

function M:setAttributeBase(attr, newBase)
  assert(self:hasAttribute(attr), sfmt("Invalid attribute %s", attr))
  self.attributes:get(attr):setBase(newBase)
  self:emit("attributeUpdate", attr, self:getAttribute(attr))
end

function M:hasEffectType(type) return self.effects:hasEffectType(type) and true end

function M:addEffect(effect) return self.effects:add(effect) end

function M:removeEffect(effect) self.effects:remove(effect) end

function M:initiateCombat(target, lag)
  lag = lag or 0
  if not self:isInCombat() then
    self.combatData.lag = lag
    self.combatData.roundStarted = os.time()
    self:emit("combatStart")
  end

  if not self:isInCombat(target) then return end

  self.combatants[target] = true
  if not target:isInCombat() then target:initiateCombat(self, 2500) end

  target:addCombatant(self)
end

function M:isInCombat(target)
  return
    target and self.combatants.has(target) or tablex.size(self.combatants) > 0
end

function M:addCombatant(target)
  if self:isInCombat(target) then return end

  self.combatants[target] = true
  target:addCombatant(self)
  self:emit("combatantAdded", target)
end

function M:removeCombatant(target)
  if not self.combatants[target] then return end

  self.combatants[target] = nil
  target:removeCombatant(self)

  self:emit("combatantRemoved", target)
  if not tablex.size(self.combatants) then self:emit("combatEnd") end
end

function M:removeFromCombat()
  if not self:isInCombat() then return end
  tablex.foreach(self.combatants,
                 function(_, combatant) self:removeCombatant(combatant) end)
end

function M:evaluateIncomingDamage(damage, currentAmount)
  local amount = self.effects:evaluateIncomingDamage(damage, currentAmount)
  return math.floor(amount)
end

function M:evaluateOutgoingDamage(damage, currentAmount)
  return self.effects:evaluateOutgoingDamage(damage, currentAmount)
end

function M:equip(item, slot)
  if self.equipment[slot] then error("equiped") end

  if item.isEquipped then error("item equipped") end

  if self.inventory then self:removeItem(item) end

  self.equipment[slot] = item
  item.isEquipped = true
  item.equippedBy = self
  item:emit("equip", self)
  self:emit("equip", slot, item)
end

function M:unequip(slot)
  if self.isInventoryFull() then error("inventory full") end

  local item = self.equipment[slot]
  item.isEquipped = false
  item.equippedBy = false
  self.equipment[slot] = nil
  item:emit("unequip", self)
  self:emit("unequip", slot, item)
  self:addItem(item)
end

function M:addItem(item)
  self:_setupInventory()
  self.inventory:addItem(item)
  item.carriedBy = self
end

function M:removeItem(item)
  self.inventory:removeItem(item)
  if not tablex.size(self.inventory) then self.inventory = false end
  item.carriedBy = false
end

function M:hasItem(itemReference)
  for _, item in pairs(self.inventory.items) do
    if item.entityReference == itemReference then return true end
    return false
  end
end

function M:isInventoryFull()
  self:_setupInventory()
  return self.inventory:isFull()
end

function M:_setupInventory()
  self.inventory = self.inventory or Inventory()
  if not self:isNpc() and type(self.inventory:getMax()) ~= "number" then
    self.inventory:setMax(Config.get("defaultMaxPlayerInventory") or 20)
  end
end

function M:follow(target)
  if target == self then
    self:unfollow()
    return
  end

  self.following = target
  target:addFollower(self)
  self:emit("followed", target)
end

function M:unfollow()
  self.following:removeFollower(self)
  self:emit("unfollowed", self.following)
  self.following = false
end

function M:addFollower(follower)
  self.followers[follower] = true
  follower.following = self
  self:emit("gainedFollower", follower)
end

function M:removeFollower(follower)
  self.followers[follower] = nil
  follower.following = false
  self:emit("lostFollower", follower)
end

function M:isFollowing(target) return self.following == target end

function M:hasFollower(target) return self.followers[target] and true end

function M:hydrate(state)
  if self.__hydrated then
    Logger.warning("Attempted to hydrate already hydrated character.")
    return false
  end

  if not Attributes:class_of(self.attributes) then
    local attributes = self.attributes
    self.attributes = Attributes()
    for attr, attrConfig in ipairs(attributes) do
      if type(attrConfig) == "number" then
        attrConfig = { base = attrConfig }
      end
      if type(attrConfig) ~= "table" or not attrConfig["base"] then
        error("Invalid base value given to attributes.\n")
      end
      if not state.AttributeFactory:has(attr) then
        error(sfmt("Entity trying to hydrate with invalid attribute %s", attr))
      end
      self:addAttribute(state.AttributeFactory:create(attr, attrConfig.base,
                                                      attrConfig.delta or 0))
    end
  end

  self.effects:hydrate(state)

  self.__hydrated = true
end

function M:serialize()
  return {
    attributes = self.attributes:serialize(),
    level      = self.level,
    name       = self.name,
    room       = self.room and self.room.entityReference,
    effects    = self.effects:serialize(),
  }
end

function M:getBroadcastTargets() return { self } end

function M:isNpc() return false end

return M
