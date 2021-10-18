local class      = require("pl.class")
local Logger     = require("core.Logger")
local tconcat    = table.concat
local tinsert    = table.insert
local tunpack    = table.unpack
local GameEntity = require("core.GameEntity")
local AreaFloor  = require("core.AreaFloor")

---@class Area :GameEntity
---@field bandle string
---@field name string
---@field title string
---@field metadata table
---@field rooms table<string,Room>
---@field npcs table<Npc,boolean>
---@field map table<number,AreaFloor>
---@field script string
---@field behaviors table<string, table> # name, config pairs
local M          = class(GameEntity)

function M:_init(bundle, name, manifest)
  self:super()
  self.bundle = bundle
  self.name = name
  self.title = manifest.title
  self.metadata = manifest.metadata or {}
  self.rooms = {}
  self.npcs = {}
  self.map = {}
  self.script = manifest.script
  self.behaviors = {}
  for k, v in ipairs(manifest.behaviors or {}) do self.behaviors[k] = v end
  self:on("updateTick", function(state) self:update(state) end)
end

function M:getAreaPath() return
  tconcat({ self.bundle, "areas", self.name }, "/") end

function M:floors()
  local res = {}
  for k, _ in pairs(self.map) do tinsert(res, k) end
  return res
end

function M:getRoomById(id) return self.rooms[id] end

function M:addRoom(room)
  self.rooms[room.id] = room
  if room.coordinates then self:addRoomToMap(room) end
  self:emit("roomAdded", room)
end

function M:removeRoom(room)
  self.rooms[room.id] = nil
  self:emit("roomRemoved", room)
end

function M:addRoomToMap(room)
  assert(room.coordinates, "Room does not have coordinates")
  local x, y, z = tunpack(room.coordinates)
  if not self.map[z] then self.map[z] = AreaFloor(z) end
  local floor   = self.map[z]
  floor:addRoom(x, y, room)
end

function M:getRoomAtCoordinates(x, y, z)
  local floor = self.map[z]
  return floor and floor:getRoom(x, y)
end

function M:addNpc(npc) self.npcs[npc] = true end

function M:removeNpc(npc) self.npcs[npc] = nil end

function M:update(state)
  for id, room in pairs(self.rooms) do room:emit("updateTick") end
  for npc, _ in pairs(self.npcs) do npc:emit("updateTick") end
end

---@param state GameState
function M:hydrate(state)
  Logger.verbose("\t\thydrate")
  self:setupBehaviors(state.AreaBehaviorManager)
  local rooms = state.AreaFactory:getDefinition(self.name).rooms
  for _, roomRef in ipairs(rooms) do
    Logger.verbose("\t\tCreate Room:%s", roomRef)
    local room = state.RoomFactory:create(self, roomRef)
    self:addRoom(room)
    state.RoomManager:addRoom(room)
    room:hydrate(state)
    room:emit("ready")
  end
end

function M:getBroadcastTargets()
  local roomTargets = {}
  for id, room in pairs(self.rooms) do
    for _, target in ipairs(room:getBroadcastTargets()) do
      tinsert(roomTargets, target)
    end
  end
  return roomTargets
end

return M
