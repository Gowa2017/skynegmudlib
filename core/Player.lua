local sfmt         = string.format
local Character    = require("core.Character")
local CommandQueue = require("core.CommandQueue")
local Config       = require("core.Config")
local QuestTracker = require("core.QuestTracker")
local Logger       = require("core.Logger")
local PlayerRoles  = require("core.PlayerRoles")
local tablex       = require("pl.tablex")
---@class QuestData
---@field completed any[]
---@field active any[]

---@class Player : Character
---@field account Account
---@field experience number
---@field password string
---@field socket number  fd
---@field questTracker QuestTracker
---@field extraPrompts table<string,function>
---@field questData QuestData[]
---@field commandQueue CommandQueue
local M            = class(Character)

function M:_init(data)
  self:super(data)
  self.account = data.account or false
  self.experience = data.experience or 0
  self.extraPrompts = {}
  self.password = data.password
  self.prompt = data.prompt or "> "
  self.socket = data.socket or nil
  local questData = tablex.update({ completed = {}, active    = {} },
                                  data.quests or {})

  self.questTracker = QuestTracker(self, questData.active, questData.completed)
  self.commandQueue = CommandQueue()
  self.role = data.role or PlayerRoles.PLAYER
  if type(self.inventory:getMax()) ~= "number" then
    self.inventory:setMax(Config.get("defaultMaxPlayerInventory") or 20)
  end
end

function M:queueCommand(executable, lag)
  local index = self.commandQueue:enqueue(executable, lag)
  self:emit("commandQueued", index)
end

function M:emit(event, ...)
  if self.__pruned or not self.__hydrated then return end
  Logger.debug("Player event %s", event)
  Character.emit(self, event, ...)
  self.questTracker:emit(event, ...)
end

function M:interpolatePrompt(promptStr, extraData)
  extraData = extraData or {}
  local attributeData = {}
  for attr, _ in pairs(self.attributes) do
    attributeData[attr] = {
      current = self:getAttribute(attr),
      max     = self:getMaxAttribute(attr),
      base    = self:getBaseAttribute(attr),
    }
  end
  local promptData    = tablex.update(attributeData, extraData)

  -- let matches = null
  -- while (matches = promptStr.match(/%([a-z\.]+)%/)) {
  --   local token = matches[1]
  --   let promptValue = token.split('.').reduce((obj, index) => obj && obj[index], promptData)
  --   if (promptValue === null || promptValue === undefined) {
  --     promptValue = 'invalid-token'
  --   }
  --   promptStr = promptStr.replace(matches[0], promptValue)
  -- }

  return promptStr
end

function M:addPrompt(id, renderer, removeOnRender)
  removeOnRender = removeOnRender == nil and false or removeOnRender
  self.extraPrompts[id] = { removeOnRender, renderer }
end

function M:removePrompt(id) self.extraPrompts[id] = nil end

function M:hasPrompt(id) return self.extraPrompts[id] end

function M:moveTo(nextRoom, onMoved)
  onMoved = onMoved == nil and function() end or onMoved
  local prevRoom = self.room
  if self.room and self.room ~= nextRoom then
    self.room:emit("playerLeave", self, nextRoom)
    self.room:removePlayer(self)
  end

  self.room = nextRoom
  nextRoom:addPlayer(self)

  onMoved()
  nextRoom:emit("playerEnter", self, prevRoom)
  self:emit("enterRoom", nextRoom)
end

function M:save(callback)
  if not self.__hydrated then return end

  self:emit("save", callback)
end

function M:hydrate(state)
  Character.hydrate(self, state)

  self.questTracker:hydrate(state)

  if type(self.account) == "string" then
    self.account = state.AccountManager:getAccount(self.account)
  end

  self.inventory:hydrate(state, self)

  if self.equipment and type(self.equipment) ~= "table" then
    local eqDefs = self.equipment
    self.equipment = {}
    for _, slot in eqDefs do
      local itemDef = eqDefs[slot]
      local newItem = state.ItemFactory:create(
                        state.AreaManager:getArea(itemDef.area),
                        itemDef.entityReference)
      newItem:initializeInventory(itemDef.inventory)
      newItem:hydrate(state, itemDef)
      state.ItemManager:add(newItem)
      self:equip(newItem, slot)
    end
  else
    self.equipment = {}
  end

  if type(self.room) == "string" then
    local room = state.RoomManager:getRoom(self.room)
    if not room then
      Logger.error(sfmt("ERROR: Player %s was saved to invalid room %s.",
                        self.name, self.room))
      room = state.AreaManager:getPlaceholderArea():getRoomById("placeholder")
    end

    self.room = room
    self:moveTo(room)
  end
end

function M:serialize()
  local data = tablex.update(Character.serialize(self), {
    account    = self.account.username,
    experience = self.experience,
    inventory  = self.inventory and self.inventory:serialize(),
    metadata   = self.metadata,
    password   = self.password,
    prompt     = self.prompt,
    quests     = self.questTracker:serialize(),
    role       = self.role,
  })

  if type(self.equipment) == "table" then
    local eq = {}
    for slot, item in pairs(self.equipment) do eq[slot] = item:serialize() end
    data.equipment = eq
  else
    data.equipment = nil
  end
  return data
end

return M
