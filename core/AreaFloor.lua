local class = require("pl.class")
local sfmt  = string.format
---@class AreaFloor : Class
local M     = class()

function M:_init(z)
  self.z = z
  self.lowX, self.highX, self.lowY, self.highY = 0, 0, 0, 0
  self.map = {}
end

function M:addRoom(x, y, room)
  assert(room, "Invalid room given to AreaFloor.addRoom")
  assert(not self:getRoom(x, y), sfmt(
           "AreaFloo.addroom: trying to add room at filled coordinates:%d,%d",
           x, y))
  self.lowX = x < self.lowX and x
  self.highX = x > self.highX and x
  self.lowY = y < self.lowY and y
  self.highY = y > self.highY and y
  if type(self.map[x]) ~= "table" then self.map[x] = {} end
  self.map[x][y] = room
end

function M:getRoom(x, y) return self.map[x][y] end

function M:removeRoom(x, y)
  if not (self.map[x] or self.map[x][y]) then
    error("AreaFloor.removeRoom: trying to remove non-existent room")
  end
  self.map[x][y] = nil
end

return M
