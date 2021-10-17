local class        = require("pl.class")
local EventEmitter = require("core.EventEmitter");
---@class GameServer : EventEmitter
local M            = class(EventEmitter)

function M:startup(commander) self:emit("startup", commander) end

function M:shutdown() self:emit("shutdown") end

return M
