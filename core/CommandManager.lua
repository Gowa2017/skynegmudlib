local class  = require("pl.class")
local tablex = require("pl.tablex")
---@class CommandManager : Class
local M      = class()

function M:_init() self.commands = {} end

function M:get(command) return self.commands[command] end

function M:add(command)
  self.commands[command.name] = command
  if command.aliases then
    tablex.foreachi(command.aliases,
                    function(alias, _) self.commands[alias] = command end)
  end
end
function M:remove(command) self.commands[command.name] = nil end

function M:find(search, returnAlias)
  for name, command in ipairs(self.commands) do
    if name:find(search) == 1 then
      return returnAlias and { command = command, alias   = name } or command
    end
  end
end

return M
