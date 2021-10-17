local sfmt         = string.format
local uuid         = require("core.lib.uuid")
local Attributes   = require("core.Attributes")
local Character    = require("core.Character")
local Config       = require("core.Config")
local Logger       = require("core.Logger")
local Scriptable   = require("core.Scriptable")
local CommandQueue = require("core.CommandQueue")
local tablex       = require("pl.tablex")

---@class Npc : Character, Scriptable
local M            = Scriptable(class(Character))
function M:_init(area, data)
  self:super(data)
  local validate = { "keywords", "name", "id" }
  for _, prop in ipairs(validate) do
    if not data[prop] then
      assert(sfmt("NPC in area [%s] missing required property [%s]", area.name,
                  prop))
    end
  end
  self.area = data.area
  self.script = data.script
  self.behaviors = tablex.copy(data.behaviors or {})
  self.equipment = {}
  self.defaultEquipment = data.equipment or {}
  self.defaultItems = data.items or {}
  self.description = data.description
  self.entityReference = data.entityReference
  self.id = data.id
  self.keywords = data.keywords
  self.quests = data.quests or {}
  self.uuid = data.uuid or uuid()
  self.commandQueue = CommandQueue()
end

function M:moveTo(nextRoom, onMoved)
  onMoved = onMoved == nil and function() end or onMoved
  local prevRoom = self.room
  if self.room then
    self.room:emit("npcLeave", self, nextRoom)
    self.room:removeNpc(self)
  end

  self.room = nextRoom
  nextRoom:addNpc(self)

  onMoved()

  nextRoom:emit("npcEnter", self, prevRoom)
  self:emit("enterRoom", nextRoom)
end

function M:hydrate(state)
  Character.hydrate(self, state)
  state.MobManager:addMob(self)

  self:setupBehaviors(state.MobBehaviorManager)

  for _, defaultItemId in ipairs(self.defaultItems) do
    Logger.info(sfmt("\tDIST: Adding item [%d] to npc [%s]", defaultItemId,
                     self.name))
    local newItem = state.ItemFactory:create(self.area, defaultItemId)
    newItem:hydrate(state)
    state.ItemManager:add(newItem)
    self:addItem(newItem)
  end

  for slot, defaultEqId in pairs(self.defaultEquipment) do
    Logger.info(sfmt("\tDIST: Equipping item [%s] to npc [%s] in slot [%s]",
                     defaultEqId, self.name, slot))
    local newItem = state.ItemFactory:create(self.area, defaultEqId)
    newItem:hydrate(state)
    state.ItemManager:add(newItem)
    self:equip(newItem, slot)
  end
end

function M:isNpc() return true end

return M
