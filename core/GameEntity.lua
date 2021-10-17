local Scriptable   = require("core.Scriptable")
local Metadatable  = require("core.Metadatable")
local EventEmitter = require("core.EventEmitter")

---所有游戏内的实体都是可以有元数据和可挂脚本的
---@class GameEntity : EventEmitter, Scriptable, Metadatable
local M            = Scriptable(Metadatable(EventEmitter))

return M
