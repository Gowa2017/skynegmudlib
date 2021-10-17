local class       = require("pl.class")
local CommandType = require("core.CommandType")
local PlayerRoles = require("core.PlayerRoles")

---@class Command : Class
local M           = class()

function M:_init(bundle, name, def, file)
  self.bundle = bundle
  self.type = def.type or CommandType.COMMAND
  self.name = name
  self.func = def.command
  self.aliases = def.aliases
  self.usage = def.usage or self.name
  self.requiredRole = def.requiredRole or PlayerRoles.PLAYER
  self.file = file
  self.metadata = def.metadata or {}
end

function M:execute(args, player, args0) return self:func(args, player, args0) end

return M
