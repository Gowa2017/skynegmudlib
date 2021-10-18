local class = require("pl.class")
---@class RoomManager : Class
local M     = class()

function M:_init() self.rooms = {} end

function M:getRoom(entityRef) return self.rooms[entityRef] end

function M:addRoom(room) self.rooms[room.entityReference] = room end

function M:removeRoom(room) self.rooms[room.entityReference] = nil end

return M
