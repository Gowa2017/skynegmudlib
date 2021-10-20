local class      = require("pl.class")
local sfmt       = string.format
local tunpack    = table.unpack
local tinsert    = table.insert
local GameEntity = require("core.GameEntity")
local Logger     = require("core.Logger")
local tablex     = require("pl.tablex")
---@class Exit
---@field id number
---@field direction string

---@class Coordinates
---@field x number
---@field y number
---@field z number

---@class Room :GameEntity
---@field area         Area           Area room is in
---@field coordinates  Coordinates       {x,y,z}
---@field defaultItems number[]       Default list of item ids that should load in self room
---@field defaultNpcs  number[]      Default list of npc ids that should load in self room
---@field description  string        Room description seen on 'look'
---@field exits        Exit[]          Exits out of self room { id: number, direction: string }
---@field id           number        Area-relative id (vnum)
---@field items        talbe<Item ,boolean>          Items currently in the room
---@field npcs         table<Npc,boolean>          Npcs currently in the room
---@field players      table<Player ,boolean>          Players currently in the room
---@field script       string        Name of custom script attached to self room
---@field title        string        Title shown on look/scan
---@field doors        table[]        Doors restricting access to self room. See documentation for format
local M          = class(GameEntity)

---@param area Area
---@param def table
function M:_init(area, def)
  self:super()
  local required = { "title", "description", "id" }
  for _, prop in ipairs(required) do
    assert(def[prop], sfmt(
             "ERROR: AREA[%s] Room does not have required property %s",
             area.name, prop))
  end
  self.def = def
  self.area = area
  self.defaultItems = def.items or {}
  self.defaultNpcs = def.npcs or {}
  self.metadata = def.metadata or {}
  self.script = def.script
  self.behaviors = tablex.copy(def.behaviors or {})
  self.coordinates =
    type(def.coordinates) == "table" and #def.coordinates == 3 and
      { x = def.coordinates[1], y = def.coordinates[2], z = def.coordinates[3] } or
      false
  self.description = def.description
  self.entityReference = self.area.name .. ":" .. def.id
  self.exits = def.exits or {}
  self.id = def.id
  self.title = def.title
  self.doors = table.concat(def.doors or {})
  self.defaultDoors = def.doors

  self.items = {}
  self.npcs = {}
  self.players = {}

  self.spawnedNpcs = {}
end

local function emit(_, o, event, ...) o:emit(event, ...) end

function M:emit(eventName, ...)
  GameEntity.emit(self, eventName, ...)

  local proxiedEvents = { "playerEnter", "playerLeave", "npcEnter", "npcLeave" }

  if tablex.find(proxiedEvents, eventName) then
    tablex.foreach(self.npcs, emit, eventName, ...)
    tablex.foreach(self.players, emit, eventName, ...)
    tablex.foreach(self.items, emit, eventName, ...)
  end
end

function M:addPlayer(player) self.players[player] = true end

function M:removePlayer(player) self.players[player] = nil end

function M:addNpc(npc)
  self.npcs[npc] = true
  npc.room = self
  self.area:addNpc(npc)
end

function M:removeNpc(npc, removeSpawn)
  removeSpawn = removeSpawn == nil and false or removeSpawn
  self.npcs[npc] = nil
  if removeSpawn then self.spawnedNpcs[npc] = nil end
  npc.room = nil
end

function M:addItem(item)
  self.items[item] = true
  item.room = self
end

function M:removeItem(item)
  self.items[item] = nil
  item.room = nil
end

function M:getExits()
  local exits     = tablex.map(function(exit)
    exit.inferred = false;
    return exit
  end, self.exits)
  if not self.area or not self.coordinates then return exits end

  local adjacents = {
    { dir   = "west", coord = { -1, 0, 0 } },
    { dir   = "east", coord = { 1, 0, 0 } },
    { dir   = "north", coord = { 0, 1, 0 } },
    { dir   = "south", coord = { 0, -1, 0 } },
    { dir   = "up", coord = { 0, 0, 1 } },
    { dir   = "down", coord = { 0, 0, -1 } },
    { dir   = "northeast", coord = { 1, 1, 0 } },
    { dir   = "northwest", coord = { -1, 1, 0 } },
    { dir   = "southeast", coord = { 1, -1, 0 } },
    { dir   = "southwest", coord = { -1, -1, 0 } },
  }
  for _, adj in ipairs(adjacents) do
    local x, y, z = tunpack(adj.coord)
    local room    = self.area:getRoomAtCoordinates(self.coordinates.x + x,
                                                   self.coordinates.y + y,
                                                   self.coordinates.z + z)
    if room then
      local ok
      for _, ex in ipairs(self.exits) do
        if ex.direction == adj.dir then
          ok = true
          break
        end
      end
      if not ok then
        exits[#exits + 1] = {
          roomId    = room.entityReference,
          direction = adj.dir,
          inferred  = true,
        }
      end
    end
  end

  return exits
end

function M:findExit(exitName)
  local exits    = self:getExits()
  if not exits or #exits < 1 then return false end

  local roomExit
  for _, ex in ipairs(exits) do
    local s, _ = ex.direction:find(exitName)
    if s == 0 then
      roomExit = ex
      break
    end
  end

  return roomExit or false
end

function M:getExitToRoom(nextRoom)
  local exits    = self:getExits()

  if not exits or #exits < 1 then return false end
  local roomExit
  for _, ex in ipairs(exits) do
    if ex.roomId == nextRoom.entityReference then
      roomExit = ex
      break
    end
  end

  return roomExit or false
end

function M:hasDoor(fromRoom) return self.doors[fromRoom.entityReference] end

function M:getDoor(fromRoom)
  if not fromRoom then return end
  return self.doors[fromRoom.entityReference]
end

function M:isDoorLocked(fromRoom)
  local door = self:getDoor(fromRoom)
  if not door then return false end
  return door.locked
end

function M:openDoor(fromRoom)
  local door = self:getDoor(fromRoom)
  if not door then return end
  door.closed = false
end

function M:closeDoor(fromRoom)
  local door = self:getDoor(fromRoom)
  if not door then return end
  door.closed = true
end

function M:unlockDoor(fromRoom)
  local door = self:getDoor(fromRoom)
  if not door then return end

  door.locked = false
end

function M:lockDoor(fromRoom)
  local door = self:getDoor(fromRoom)
  if not door then return end

  self:closeDoor(fromRoom)
  door.locked = true
end

function M:spawnItem(state, entityRef)
  Logger.info(sfmt("\tSPAWN: Adding item [%s] to room [%s]", entityRef,
                   self.title))
  local newItem = state.ItemFactory:create(self.area, entityRef)
  newItem:hydrate(state)
  newItem.sourceRoom = self
  state.ItemManager:add(newItem)
  self:addItem(newItem)
  newItem:emit("spawn")
  return newItem
end

function M:spawnNpc(state, entityRef)
  Logger.info(sfmt("\tSPAWN: Adding npc [%s] to room [%s]", entityRef,
                   self.title))
  local newNpc = state.MobFactory:create(self.area, entityRef)
  newNpc:hydrate(state)
  newNpc.sourceRoom = self
  self.area:addNpc(newNpc)
  self:addNpc(newNpc)
  self.spawnedNpcs[newNpc] = true
  newNpc:emit("spawn")
  return newNpc
end

function M:hydrate(state)
  self:setupBehaviors(state.RoomBehaviorManager)

  self:emit("spawn")

  self.items = {}

  for i, v in ipairs(self.defaultItems) do
    if type(v) == "string" then self.defaultItems[i] = { id = v } end
    self:spawnItem(state, self.defaultItems[i].id)
  end
  for i, v in ipairs(self.defaultNpcs) do
    if type(v) == "string" then self.defaultNpcs[i] = { id = v } end
    self:spawnNpc(state, self.defaultNpcs[i].id)
  end
end

function M:getBroadcastTargets()
  local targets =
    tablex.merge(tablex.keys(self.players), tablex.keys(self.npcs))
  tinsert(targets, 1, self)
  return targets
end

return M
